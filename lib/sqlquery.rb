module Sqlquery
	def run_sql(argv)
		ActiveRecord::Base.connection.execute(ActiveRecord::Base.send(:sanitize_sql_array, argv) )
	end

end