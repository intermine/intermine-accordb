define [
    'chaplin'
], (Chaplin) ->

    class Layout extends Chaplin.Layout

        initialize: ->
            super
            
            @subscribeEvent 'startupController', @changeMenuLink

        changeMenuLink: (context) ->
            $('#sidebar li').removeClass('active')
            $("#sidebar li[data-controller='#{context.controller.whoAmI}']").addClass('active')