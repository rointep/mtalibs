-----------------------------------------------------------------------
--
-- MTA Database Library
-- Version: 2.0
--
-----------------------------------------------------------------------


-- Syntax structure:
--
-- returnValueType | function:Name ( argumentType argumentName, ... )



-- MDO
MDO = {}


-- libraryHandler | MDO:Create ( string host, string username, string password, string database )
function MDO:Create(host, username, password, database)
	local newConnection = {
			host = host,
			username = username,
			password = password,
			database = database,
		}

	newConnection.informationalID = "[MDO:" .. tostring(newConnection):gsub("table: ", "", 1, true) .. "]"

	setmetatable(newConnection, {__index = MDO})

	return newConnection
end



-- mysqlHandler | MDO:Connect ( void )
function MDO:Connect()
	self.connection = dbConnect("mysql", "dbname="..self.database..";host="..self.host, self.username, self.password, "share=0")
	outputDebugString(self.informationalID .. " Connecting to database '" .. self.database .. "'")
	return self.connection
end



-- resultsTable, numberOfResults [,callbackArg1, callbackArg2, ...] | MDO:Query ( function callbackFn, table callbackArgs, string query, mixed parameters)
function MDO:Query(callback, callbackArgs, query, ...)
	if self.connection then
		self.lastQuery = dbQuery(
			function(qh)
				local results, numrows, errorMsg = dbPoll(qh, 0)
				if not results then
					outputDebugString(self.informationalID .. " Query [".. numrows .. "] \"" .. errorMsg .. "\"", 1)
					return nil
				end

				self.numRows = numrows
				self.results = results

				callback(results, numrows, unpack(callbackArgs))
			end, self.connection, query, unpack( {...} ))
		
		return self.lastQuery
	end

	return false
end


-- boolean | MDO:Exec ( string query, mixed parameters )
function MDO:Exec(query, ...)
	self.lastExec = dbExec(self.connection, query, unpack( {...} ))
	return self.lastExec
end


-- int | MDO:NumRows ( void )
function MDO:NumRows()
	if self.numRows then
		return self.numRows
	end
	return false
end


-- resultsTable | MDO:Results( void )
function MDO:Results()
	if self.results then
		return self.results
	end
	return false
end


-- boolean | MDO:Free ( void )
function MDO:Free()
	if self.lastQuery then
		self.numRows = nil
		self.results = nil
		return dbFree(self.lastQuery)
	end

	return false
end
