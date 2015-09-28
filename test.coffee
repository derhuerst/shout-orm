mocha =			require 'mocha'
assert =		require 'assert'
shortid =		require 'shortid'

orm =			require './index'





# todo: start redis first
orm.connect()



describe 'groups', () ->

	testGroup =
		key:	'abcdefg'
		locked:	true

	it 'should `add` & `get` data correctly', (done) ->
		orm.groups.add 'one', testGroup.key, testGroup.locked
		.then () ->
			orm.groups.get 'one'
			.then (group) ->
				assert.deepEqual group, testGroup
				done()

	it 'should correctly check if a group exists', (done) ->
		orm.groups.has 'one'
		.then (exists) ->
			assert.strictEqual exists, true
			done()

	it 'should correctly lock a group', (done) ->
		orm.groups.add 'one', testGroup.key, false
		.then () -> orm.groups.lock 'one'
		.then () -> orm.groups.get 'one'
		.then (group) -> assert.strictEqual group.locked, true
		.then () -> orm.groups.rm 'one'
		.then () -> done()

	it 'should correctly remove a group', (done) ->
		orm.groups.rm 'one'
		.then () -> orm.groups.has 'one'
		.then (exists) ->
			assert.strictEqual exists, false
			done()



describe 'users', () ->

	testUser =
		token:	'test token'
		system:	'ios'

	it 'should `add` & `get` data correctly', (done) ->
		orm.users.add 'one', testUser.system, testUser.token
		.then () ->
			orm.users.get 'one'
			.then (user) ->
				assert.deepEqual user, testUser
				done()

	it 'should correctly check if a user exists', (done) ->
		orm.users.has 'one'
		.then (exists) ->
			assert.strictEqual exists, true
			done()

	it 'should correctly remove a user', (done) ->
		orm.users.rm 'one'
		.then () -> orm.users.has 'one'
		.then (exists) ->
			assert.strictEqual exists, false
			done()



describe 'registrations', () ->

	testRegistration = 'test token'
	testUser =
		token:	'test token'
		system:	'ios'

	it 'should `add` & `get` data correctly', (done) ->
		orm.registrations.add 'one', testRegistration
		.then () -> orm.registrations.get 'one'
		.then (registration) ->
			assert.deepEqual registration, testRegistration
			done()

	it 'should correctly check if a registration exists', (done) ->
		orm.registrations.has 'one'
		.then (exists) ->
			assert.strictEqual exists, true
			done()

	it 'should correctly remove a registration', (done) ->
		orm.registrations.rm 'one'
		.then () -> orm.registrations.has 'one'
		.then (exists) ->
			assert.strictEqual exists, false
			done()

	it 'should correctly activate a registration', (done) ->
		orm.registrations.add 'two', testRegistration
		.then () ->
			orm.registrations.activate 'two', testUser.system, testUser.token
		.then () -> orm.users.get 'two'
		.then (user) -> assert.deepEqual user, testUser
		.then () -> orm.users.rm 'two'
		.then () -> done()



describe 'messages', () ->

	testGroup =
		key:	'abcdefg'
		locked:	false
	testMessage1 =
		body:	'test message 1'
		date:	Date.now()
	testMessage2 =
		body:	'test message 2'
		date:	Date.now() + 1000

	it 'should `add` & `get` data correctly', (done) ->
		orm.groups.add 'one', testGroup.key, testGroup.locked
		.then () -> orm.messages.add 'one', 'two', testMessage1.body, testMessage1.date
		.then () -> orm.messages.get 'one', 'two'
		.then (message) -> assert.deepEqual message, testMessage1
		.then () -> orm.messages.rm 'one', 'two'
		.then () -> orm.groups.rm 'one'
		.then () -> done()

	it 'should fail on `add` if the group is locked', (done) ->
		orm.groups.add 'one', testGroup.key, true
		.then () -> orm.messages.add 'one', 'two', testMessage1.body, testMessage1.date
		.then (() ->
			orm.messages.get 'one', 'two'
			.then (message) ->
				orm.messages.rm 'one', 'two'
				.then () -> assert.fail message, null, '`add` added to a locked group'
		), (err) ->
			assert.ok true, '`add` threw an exception'
		.finally () ->
			orm.groups.rm 'one'
			.then () -> done()

	it 'should get `all` messages correctly', (done) ->
		orm.groups.add 'one', testGroup.key, testGroup.locked
		.then () -> orm.messages.add 'one', 'two', testMessage1.body, testMessage1.date
		.then () -> orm.messages.add 'one', 'three', testMessage2.body, testMessage2.date
		.then () -> orm.messages.all 'one'
		.then (messages) ->
			assert.deepEqual messages, [ testMessage1, testMessage2 ]
		.then () -> orm.messages.rm 'one', 'two'
		.then () -> orm.messages.rm 'one', 'three'
		.then () -> orm.groups.rm 'one'
		.then () -> done()



describe 'subscribers', () ->

	testGroup =
		key:	'abcdefg'
		locked:	false
	testSubscriber1 = Date.now()
	testSubscriber2 = Date.now() + 1000

	it 'should `add` & `get` data correctly', (done) ->
		orm.groups.add 'one', testGroup.key, testGroup.locked
		.then () -> orm.subscribers.add 'one', 'two', testSubscriber1
		.then () -> orm.subscribers.get 'one', 'two'
		.then (subscriber) -> assert.strictEqual subscriber, testSubscriber1
		.then () -> orm.subscribers.rm 'one', 'two'
		.then () -> orm.groups.rm 'one'
		.then () -> done()

	it 'should get `all` subscribers correctly', (done) ->
		orm.groups.add 'one', testGroup.key, testGroup.locked
		.then () -> orm.subscribers.add 'one', 'two', testSubscriber1
		.then () -> orm.subscribers.add 'one', 'three', testSubscriber2
		.then () -> orm.subscribers.all 'one'
		.then (all) ->
			assert.strictEqual all.length, 2
			assert all.indexOf(testSubscriber1) >= 0, '`testSubscriber1` exists'
			assert all.indexOf(testSubscriber2) >= 0, '`testSubscriber2` exists'
		.then () -> orm.subscribers.rm 'one', 'two'
		.then () -> orm.subscribers.rm 'one', 'three'
		.then () -> orm.groups.rm 'one'
		.then () -> done()
