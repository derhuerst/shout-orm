Promise =		require 'bluebird'
redis =			require 'redis'





module.exports =



	port:		6389
	host:		'localhost'

	redis:		null

	_get:		null
	_set:		null
	_keys:		null



	connect: () ->
		return this if @redis   # already connected

		@redis = redis.createClient @port, @host

		@_get = Promise.promisify redis.get
		@_set = Promise.promisify redis.set
		@_keys = Promise.promisify redis.keys

		return this



	getGroup: (name) ->
		return @_get "g:#{name}"
		.then (data) ->
			data = JSON.parse data
			return
				key:	data.k
				locked:	data.l

	setGroup: (name, key, locked) ->
		data = JSON.stringify
			k:	key
			l:	locked
		return @_set "g:#{name}", data



	getMessage: (group, id) ->
		return @_get "m:#{group}#{id}"
		.then (data) ->
			data = JSON.parse data
			return
				date:	data.d
				body:	data.b

	getMessagesOfGroup: (group) ->
		# todo: support streams
		return new Promise (resolve, reject) ->
			results = []
			@_keys "m:#{group}:*"
			.then (ids) ->
				async.eachLimit ids, 50, ((id, cb) ->
					# todo: use [redis transactions](http://redis.io/topics/transactions) or at least [redis pipelining](http://redis.io/topics/pipelining)
					@getMessage group, id
					.then (message) ->
						results.push message
				), () ->
					resolve results

	setMessage: (group, id, date, body) ->
		data = JSON.stringify
			d:	date
			b:	body
		return @_set "m:#{group}#{id}", data



	getUser: (group, id) ->
		return @_get "u:#{group}#{id}"
		.then (data) ->
			data = JSON.parse data
			return
				system:	data.s
				token:	data.t

	getUsersOfGroup: (group) ->
		# todo: support streams
		return new Promise (resolve, reject) ->
			results = []
			@_keys "u:#{group}:*"
			.then (ids) ->
				async.eachLimit ids, 50, ((id, cb) ->
					# todo: use [redis transactions](http://redis.io/topics/transactions) or at least [redis pipelining](http://redis.io/topics/pipelining)
					@getUser group, id
					.then (user) ->
						results.push user
				), () ->
					resolve results

	setUser: (group, id, system, token) ->
		data = JSON.stringify
			s:	system
			t:	token
		return @_set "u:#{group}#{id}", data
