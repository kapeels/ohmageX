@Ohmage.module "Entities", ((Entities, App, Backbone, Marionette, $, _, ConditionalParser) ->

  # This oldCondition Entity currently references the Conditional
  # Parser code from the previous version of ohmage MWF,
  # stored in a vendor lib file. It acts as a middleware
  # for the data sent to the old library.

  API =

    prepParser: (rawCondition, responses) ->
      oldParserResponses = {}
      responses.each((response) =>
        myId = response.get 'id'

        myResponse = App.request "response:value:parsed", 
          conditionValue: true
          stepId: myId
          addUploadUUIDs: false

        oldParserResponses[myId] = myResponse
        oldParserResponses
      )

      console.log 'oldParserResponses', @mergeMessagePrompts oldParserResponses

      trimCondition = rawCondition.replace(/\)\s*(and|or)\s*\(/i, ") $1 (")
      trimCondition = trimCondition.replace(/\s*(==|!=|<=|=>|>|<)\s*/i, " $1 ")
      ConditionalParser.parse trimCondition, @mergeMessagePrompts oldParserResponses

    mergeMessagePrompts: (oldParserResponses) ->
      messageIds = App.request "flow:message:ids"

      if messageIds
        messageResponses = {}
        _.each messageIds, (id) => messageResponses[id] = App.request 'flow:message:value', id

        _.extend oldParserResponses, messageResponses
      else
        oldParserResponses

  App.reqres.setHandler "oldcondition:evaluate", (rawCondition, responses) ->
    API.prepParser rawCondition, responses

), ConditionalParser