mongojs = require 'mongojs'
moment = require 'moment'
Datastore = require 'meshblu-core-datastore'
UpdateDevice = require '../'

describe 'UpdateDevice', ->
  beforeEach (done) ->
    @uuidAliasResolver = resolve: (uuid, callback) => callback(null, uuid)
    @datastore = new Datastore
      database: mongojs('meshblu-core-task-update-device')
      moment: moment
      collection: 'devices'

    @datastore.remove done

  beforeEach ->
    @sut = new UpdateDevice {@datastore, @uuidAliasResolver}

  describe '->do', ->
    describe 'when the device does not exist in the datastore', ->
      beforeEach (done) ->
        request =
          metadata:
            responseId: 'used-as-biofuel'
            auth:
              uuid: 'thank-you-for-considering'
              token: 'the-environment'
            toUuid: '2-you-you-eye-dee'
          rawData: '{}'

        @sut.do request, (error, @response) => done error

      it 'should respond with a 404', ->
        expect(@response.metadata.code).to.equal 404

    describe 'when the device does exists in the datastore', ->
      beforeEach (done) ->
        record =
          uuid: '2-you-you-eye-dee'
          token: 'never-gonna-guess-me'
          meshblu:
            tokens:
              'GpJaXFa3XlPf657YgIpc20STnKf2j+DcTA1iRP5JJcg=': {}
        @datastore.insert record, done

      describe 'when called', ->
        beforeEach (done) ->
          request =
            metadata:
              responseId: 'used-as-biofuel'
              auth:
                uuid: 'thank-you-for-considering'
                token: 'the-environment'
              toUuid: '2-you-you-eye-dee'
            rawData: JSON.stringify $set: {sandbag: "this'll hold that pesky tsunami!"}

          @sut.do request, (error, @response) => done error

        it 'should respond with a 204', ->
          expect(@response.metadata.code).to.equal 204

        describe 'when the record is retrieved', ->
          beforeEach (done) ->
            @datastore.findOne uuid: '2-you-you-eye-dee', (error, @record) =>
              done error

          it 'should update the record', ->
            expect(@record).to.containSubset
              sandbag: "this'll hold that pesky tsunami!"

          it 'should update/set the updatedAt time',->
            expect(@record.meshblu.updatedAt).to.exist
            updatedAt = moment(@record.meshblu.updatedAt).valueOf()
            expect(updatedAt).to.be.closeTo moment().valueOf(), 3000

          it 'should store a hash of the device', ->
            expect(@record.meshblu.hash).to.exist

      describe 'when request is for the wrong uuid', ->
        beforeEach (done) ->
          request =
            metadata:
              responseId: 'used-as-biofuel'
              auth:
                uuid: 'thank-you-for-considering'
                token: 'the-environment'
              toUuid: 'skin-falls-off'
            rawData: '{}'

          @sut.do request, (error, @response) => done error

        it 'should respond with a 404', ->
          expect(@response.metadata.code).to.equal 404

      describe 'when request contains invalid JSON', ->
        beforeEach (done) ->
          request =
            metadata:
              responseId: 'used-as-biofuel'
              auth:
                uuid: 'thank-you-for-considering'
                token: 'the-environment'
              toUuid: 'skin-falls-off'
            rawData: 'Ω'

          @sut.do request, (@error) => done()

        it 'should yield an error', ->
          expect(=> throw @error).to.throw 'Error parsing JSON: Unexpected token Ω'
