require_relative 'task_helper'

namespace :quattroshapes do

  task :prepare_all  => Pelias::QuattroIndexer::PATHS.map { |t, _| "prepare_#{t}" }

  Pelias::QuattroIndexer::PATHS.each do |type, file|
    t = task(:"prepare_#{type}") { perform_prepare(type, file) }
    t.add_description("download quattroshapes #{type} file and load to postgresql")
    t = task(:"populate_#{type}") { perform_index(type) }
    t.add_description("search index quattroshapes #{type}")
  end

  desc "Update qs_locality.qs_gn_id where null and fits within polygon"
  task :patch_geoname_ids do # => "geonames:add_geometry" do
    patch_sql = """
      UPDATE qs_locality
        SET gs_gn_id=(subquery.geonameid)::text, qs_gn_id=(subquery.geonameid)::text
      FROM
      (select * from (
        select l.gid, l.qs_loc, g.geonameid, g.name geoname, g.admin1 geoname_admin, population, rank()
        OVER (PARTITION BY l.gid ORDER BY g.population DESC, g.geonameid) AS poprank
        from qs_locality l, gn_geoname g
        where l.gs_gn_id is null and l.qs_gn_id is null and g.population > 0 and st_within(g.geom, l.geom)
        order by l.gid, g.geonameid, g.name, g.admin1, g.population desc
        ) missinggeoname where poprank = 1
      ) subquery
      where subquery.gid = qs_locality.gid
      """
    Pelias::DB.run(patch_sql)
  end

  private

  # Download the things we need
  def perform_prepare(type, file)
    sh "wget http://static.quattroshapes.com/#{file}.zip -P #{TEMP_PATH}" # download
    sh "unzip #{TEMP_PATH}/#{file}.zip -d #{TEMP_PATH}" # expand
    sh "shp2pgsql -s 4326 -D -d -Nskip -I -WLATIN1 #{TEMP_PATH}/#{file}.shp qs_#{type} > #{TEMP_PATH}/#{file}.sql" # convert
    sh "#{psql_command} < #{TEMP_PATH}/#{file}.sql" # import
    sh "rm #{TEMP_PATH}/#{file}*" # clean up
  end

  # Perform an index
  def perform_index(type)
    i = 0
    Pelias::DB["select gid from qs_#{type}"].use_cursor.each do |row|
      puts "Prepared #{i}" if (i += 1) % 10_000 == 0
      Pelias::QuattroIndexer.perform_async type, row[:gid]
    end
  end

  def psql_command
    c = Pelias::PG_CONFIG
    [ 'psql',
      ("-U #{c[:user]}" if c[:user]),
      ("-h #{c[:host]}" if c[:host]),
      ("-p #{c[:port]}" if c[:post]),
      c[:database]
    ].compact.join(' ')
  end

end
