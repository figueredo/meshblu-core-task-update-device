_      = require 'lodash'
uuid   = require 'uuid'
DeviceManager = require 'meshblu-core-manager-device'

class UpdateDevice
  constructor: ({datastore,uuidAliasResolver,@jobManager}) ->
    @deviceManager = new DeviceManager {datastore, uuidAliasResolver}

  do: (job, callback) =>
    {toUuid, auth} = job.metadata
    try
      update = JSON.parse job.rawData
    catch error
      return callback new Error "Error parsing JSON: #{error.message}"

    @deviceManager.update {uuid: toUuid, data: update}, (error, results) =>
      return callback error if error?
      return callback null, metadata: code: 404 unless 0 < _.first(_.pluck(results, 'n'))

      @deviceManager.findOne {uuid: toUuid}, (error, message) =>
        return callback error if error?

        newAuth =
          uuid: toUuid

        @_createJob {messageType: 'config', jobType: 'DeliverConfigMessage', toUuid: toUuid, fromUuid: toUuid, message, auth: newAuth}, (error) =>
          return callback error if error?
          return callback null, metadata: code: 204

  _createJob: ({messageType, jobType, toUuid, message, fromUuid, auth}, callback) =>
    request =
      data: message
      metadata:
        auth: auth
        toUuid: toUuid
        fromUuid: fromUuid
        jobType: jobType
        messageType: messageType
        responseId: uuid.v4()

    @jobManager.createRequest 'request', request, callback

module.exports = UpdateDevice
