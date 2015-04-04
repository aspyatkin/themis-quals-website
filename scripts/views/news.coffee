define 'newsView', ['jquery', 'view', 'renderTemplate', 'dataStore', 'navigationBar', 'metadataStore'], ($, View, renderTemplate, dataStore, navigationBar, metadataStore) ->
    class NewsView extends View
        constructor: ->
            @urlRegex = /^\/news$/

        getTitle: ->
            "#{metadataStore.getMetadata 'event-title' } :: News"

        present: ->
            $main = $ '#main'
            $('#main').html renderTemplate 'news-view'

            dataStore.getIdentity (err, identity) ->
                if err?
                    $main.html renderTemplate 'internal-error'
                    navigationBar.present()
                else
                    navigationBar.present
                        identity: identity
                        active: 'news'

        dismiss: ->
            $('#main').empty()
            navigationBar.dismiss()

    new NewsView()
