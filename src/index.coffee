Promise =		require 'bluebird'
redis =			require 'redis'
shortid =		require 'shortid'
boom =			require 'boom'





module.exports =



	port:				6379
	host:				'localhost'
	redis:				null

	p:
		user:			'u'
		group:			'g'
		userInGroup:	'ug'
		groupOfUser:	'gu'
		message:		'm'
		messageInGroup:	'mg'
		registration:	'r'
		token:			't'
		system:			's'
		body:			'b'
		date:			'd'

	s:
		apn:			0
		gcm:			1
		mpns:			2



	connect: () ->
		return this if @r   # already connected
		@r = redis.createClient @port, @host

		return this



	addUser: (system, token) ->
		id = shortid.generate()
		set = {}
		set[@p.system] = @s[system]
		set[@p.token] = token
		_ = this
		return new Promise (resolve, reject) ->
			_.r.hmset _.p.user + ':' + id, set, (err) ->
				if err then reject err
				else resolve id

	deleteUser: (id) ->
		_ = this
		return new Promise (resolve, reject) ->
			_.r.exists _.p.user + ':' + id, (err, exists) ->
				if err then return reject err
				if not exists then return reject boom.notFound "User `#{id}` doesn't exist."
				_.r.smembers _.p.groupOfUser + ':' + id, (err, groups) ->
					if err then return reject err
					multi = _.r.multi()
					for group in groups
						multi.srem _.p.userInGroup + ':' + group, id
					multi.exec (err) ->
						if err then return reject err
						resolve id
