async  = require 'async'
crypto = require 'crypto'
moment = require 'moment'
_      = require 'lodash'

class UpdateDevice
  constructor: (options={})->
    {@datastore} = options

  do: (request, callback) =>
    try
      update = JSON.parse request.rawData
    catch error
      return callback new Error "Error parsing JSON: #{error.message}"

    query = uuid: request.metadata.toUuid

    async.series [
      async.apply @update, query, update
      async.apply @updateUpdatedAt, query
      async.apply @updateHash, query
    ], (error, results) =>
      return callback error if error?
      return callback null, metadata: code: 404 unless 0 < _.first(_.pluck(results, 'n'))
      return callback null, metadata: code: 204

  update: (query, update, callback) =>
    @datastore.update query, update, callback

  updateUpdatedAt: (query, callback) =>
    @datastore.update query, $set: {'meshblu.updatedAt': moment().format()}, callback

  updateHash: (query, callback) =>
    @datastore.findOne query, (error, record) =>
      return callback error if error?
      return callback null, null unless record?

      delete record.meshblu?.hash
      hashedDevice = @hashObject record
      @datastore.update query, $set: {'meshblu.hash': hashedDevice}, callback

  hashObject: (object) =>
    hasher = crypto.createHash 'sha256'
    hasher.update JSON.stringify object
    hasher.digest 'base64'

module.exports = UpdateDevice
