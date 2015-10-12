Promise =		require 'bluebird'
redis =			require 'redis'

groups =		require './groups'
users =			require './users'
registrations =	require './registrations'
messages =		require './messages'
subscribers =	require './subscribers'





module.exports =



	port:		6379
	host:		'localhost'

	redis:		null

	_get:		null
	_set:		null
	_del:		null
	_keys:		null
	_exists:	null
	_expire:	null



	connect: () ->
		return this if @redis   # already connected

		@redis = redis.createClient @port, @host

		@_get = Promise.promisify @redis.get, @redis
		@_set = Promise.promisify @redis.set, @redis
		@_del = Promise.promisify @redis.del, @redis
		@_keys = Promise.promisify @redis.keys, @redis
		@_exists = Promise.promisify @redis.exists, @redis
		@_expire = Promise.promisify @redis.expire, @redis

		@groups = groups this
		@users = users this
		@registrations = registrations this
		@messages = messages this
		@subscribers = subscribers this

		return this
