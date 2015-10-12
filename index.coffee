Promise =		require 'bluebird'
redis =			require 'redis'
boom =			require 'boom'
async =			require 'async'
shortid =		require 'shortid'





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

		@groups._orm = this
		@users._orm = this
		@registrations._orm = this
		@messages._orm = this
		@subscribers._orm = this

		return this



	# key prefix is `g`
	groups:

		has: (name) ->
			return @_orm._exists "g:#{name}"
			.then (exists) -> !!exists

		# todo: rename to `set`?
		add: (name, key, locked = false) ->
			return @_orm._set "g:#{name}", JSON.stringify
				k:	key
				l:	locked

		get: (name) ->
			return @_orm._get "g:#{name}"
			.then (data) ->
				if not data then throw boom.notFound "Group `#{name}` doesn't exist."
				data = JSON.parse data
				return {
					key:	data.k
					locked:	data.l
				}

		lock: (name) ->
			self = this
			return @get name
			.then (group) ->
				if group.locked then return   # already locked
				else return self.add name, group.key, true

		rm: (name) -> @_orm._del "g:#{name}"



	# key prefix is `u`
	users:

		has: (id) ->
			return @_orm._exists "u:#{id}"
			.then (exists) -> !!exists

		add: (id, system, token) ->
			return @_orm._set "u:#{id}", JSON.stringify
				s:	system   # todo: use abbreviations
				t:	token

		get: (id) ->
			return @_orm._get "u:#{id}"
			.then (data) ->
				if not data then throw boom.notFound "User `#{id}` doesn't exist."
				data = JSON.parse data
				return {
					system:	data.s
					token:	data.t
				}

		rm: (id) -> @_orm._del "u:#{id}"



	# users pending for activation
	# key prefix is `r`
	registrations:

		has: (id) ->
			return @_orm._exists "r:#{id}"
			.then (exists) -> !!exists

		add: (id, token, ttl = 300) ->
			self = this
			code = shortid.generate()   # activation code
			return @_orm._set "r:#{id}", code
			.then () -> self._orm._expire "r:#{id}", 200
			.then () -> self._orm.redis.publish 'r', "#{token}:#{code}"
			.then () -> return code

		get: (id) ->
			return @_orm._get "r:#{id}"
			.then (data) ->
				if not data then throw boom.notFound "Registration `#{id}` doesn't exist."
				return data

		activate: (id, code, system, token) ->
			self = this
			return @get id
			.then (storedCode) ->
				if code isnt storedCode then throw boom.unauthorized "Wrong activation code."
				return self._orm.users.add id, system, token
			.then () -> self._orm._del "r:#{id}"

		rm: (id) -> @_orm._del "r:#{id}"



	# messages in a group
	# key prefix is `m:{group}`
	messages:

		has: (group, id) ->
			return @_orm._exists "m:#{group}:#{id}"
			.then (exists) -> !!exists

		get: (group, id) ->
			return @_orm._get "m:#{group}:#{id}"
			.then (data) ->
				if not data then throw boom.notFound "Message `#{id}` doesn't exist in group `#{group}`."
				data = JSON.parse data
				return {
					date:	data.d
					body:	data.b
				}

		add: (groupId, id, body, date = Date.now()) ->
			self = this
			return @_orm.groups.get groupId
			.then (group) ->
				if group.locked then throw new Error "The group `#{group}` is locked."
				self._orm._set "m:#{groupId}:#{id}", JSON.stringify
					d:	0 + date
					b:	body
			.then () -> self._orm.redis.publish 'm', "#{groupId}:#{id}"

		all: (group) ->
			self = this
			# todo: find a way to stream keys for performance
			return new Promise (resolve, reject) ->
				results = []
				self._orm._keys "m:#{group}:*"
				.then (ids) ->
					async.eachLimit ids, 50, ((id, cb) ->
						# todo: use [redis transactions](http://redis.io/topics/transactions) or at least [redis pipelining](http://redis.io/topics/pipelining)
						self.get group, id.split(':')[2]
						.then (message) ->
							results.push message
							cb()
					), () ->
						resolve results

		rm: (group, id) -> @_orm._del "m:#{group}:#{id}"



	# users subscribed to a group
	# key prefix is `s:{group}`
	subscribers:

		has: (group, id) ->
			return @_orm._exists "s:#{group}:#{id}"
			.then (exists) -> !!exists

		get: (group, id) ->
			return @_orm._get "s:#{group}:#{id}"
			.then (data) ->
				if not data then throw boom.notFound "User `#{id}` did not subscribe to group `#{group}`."
				return parseInt data

		add: (groupId, id, date = Date.now()) ->
			self = this
			return @_orm.groups.get groupId
			.then (group) -> self._orm._set "s:#{groupId}:#{id}", date + ''
			.then () -> self._orm.redis.publish 'm', groupId

		all: (group) ->
			self = this
			# todo: find a way to stream keys for performance
			return new Promise (resolve, reject) ->
				results = []
				self._orm._keys "s:#{group}:*"
				.then (ids) ->
					async.eachLimit ids, 50, ((id, cb) ->
						# todo: use [redis transactions](http://redis.io/topics/transactions) or at least [redis pipelining](http://redis.io/topics/pipelining)
						self.get group, id.split(':')[2]
						.then (user) ->
							results.push user
							cb()
					), () ->
						resolve results

		rm: (group, id) -> @_orm._del "s:#{group}:#{id}"
