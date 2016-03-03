_      = require 'lodash'
DeviceManager = require 'meshblu-core-manager-device'

class UpdateDevice
  constructor: ({@datastore,@uuidAliasResolver}) ->
    @deviceManager = new DeviceManager {@datastore, @uuidAliasResolver}

  do: (request, callback) =>
    {toUuid} = request.metadata
    try
      update = JSON.parse request.rawData
    catch error
      return callback new Error "Error parsing JSON: #{error.message}"

    @deviceManager.update {uuid: toUuid, data: update}, (error, results) =>
      return callback error if error?
      return callback null, metadata: code: 404 unless 0 < _.first(_.pluck(results, 'n'))
      return callback null, metadata: code: 204

module.exports = UpdateDevice
