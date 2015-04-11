define 'newsView', ['jquery', 'underscore', 'view', 'renderTemplate', 'dataStore', 'navigationBar', 'metadataStore', 'markdown-it', 'moment', 'jquery.form', 'parsley'], ($, _, View, renderTemplate, dataStore, navigationBar, metadataStore, MarkdownIt, moment) ->
    class NewsView extends View
        constructor: ->
            @$main = null
            @posts = []
            @identity = null

            @onCreatePost = null
            @onUpdatePost = null
            @onRemovePost = null

            @urlRegex = /^\/news$/

        getTitle: ->
            "#{metadataStore.getMetadata 'event-title' } :: News"

        renderPosts: ->
            $section = @$main.find 'section'
            if @posts.length == 0
                $section.empty()
                $section.html $('<p></p>').addClass('lead').text 'No news yet.'
            else
                $section.empty()
                md = new MarkdownIt()
                sortedPosts = _.sortBy(@posts, 'createdAt').reverse()
                manageable = _.contains ['admin', 'manager'], @identity.role
                for post in sortedPosts
                    options =
                        id: post.id
                        title: post.title
                        description: md.render post.description
                        updatedAt: moment(post.updatedAt).format 'lll'
                        manageable: manageable

                    $section.append $ renderTemplate 'post-partial', options

        initRemovePostModal: ->
            $buttonRemovePost = @$main.find 'button[data-action="remove-post"]'

            if $buttonRemovePost.length
                $removePostModal = $ '#remove-post-modal'
                $removePostModal.modal
                    show: no

                $removePostModalBody = $removePostModal.find '.modal-body p.confirmation'
                $removePostSubmitError = $removePostModal.find '.submit-error > p'
                $removePostSubmitButton = $removePostModal.find 'button[data-action="complete-remove-post"]'

                $removePostModal.on 'show.bs.modal', (e) =>
                    postId = parseInt $(e.relatedTarget).data('post-id'), 10
                    $removePostModal.data 'post-id', postId
                    post = _.findWhere @posts, id: postId
                    $removePostModalBody.html renderTemplate 'remove-post-confirmation', title: post.title
                    $removePostSubmitError.text ''

                $removePostSubmitButton.on 'click', (e) =>
                    postId = $removePostModal.data 'post-id'
                    dataStore.removePost postId, @identity.token, (err) ->
                        if err?
                            $removePostSubmitError.text err
                        else
                            $removePostModal.modal 'hide'


        initCreatePostModal: ->
            $buttonCreatePost = @$main.find 'button[data-action="create-post"]'
            if $buttonCreatePost.length
                $createPostModal = $ '#create-post-modal'
                $createPostModal.modal
                    show: no

                $createPostSubmitError = $createPostModal.find '.submit-error > p'
                $createPostSubmitButton = $createPostModal.find 'button[data-action="complete-create-post"]'
                $createPostForm = $createPostModal.find 'form'
                $createPostForm.parsley()

                $createPostSubmitButton.on 'click', (e) ->
                    $createPostForm.trigger 'submit'

                $createPostTablist = $ '#create-post-tablist'
                $createPostTabData = $createPostTablist.find 'a[href="#create-post-data"]'
                $createPostTabPreview = $createPostTablist.find 'a[href="#create-post-preview"]'

                $createPostTitle = $ '#create-post-title'
                $createPostDescription = $ '#create-post-description'

                $createPostPreview = $ '#create-post-preview'

                $createPostTabData.tab()
                $createPostTabPreview.tab()

                $createPostTabPreview.on 'show.bs.tab', (e) ->
                    md = new MarkdownIt()
                    options =
                        title: $createPostTitle.val()
                        description: md.render $createPostDescription.val()
                        updatedAt: moment(new Date()).format 'lll'

                    $createPostPreview.html renderTemplate 'post-simplified-partial', options

                $createPostModal.on 'show.bs.modal', (e) ->
                    $createPostTabData.tab 'show'
                    $createPostTitle.val ''
                    $createPostDescription.val ''
                    $createPostSubmitError.text ''

                $createPostModal.on 'shown.bs.modal', (e) ->
                    $createPostTitle.focus()

                $createPostForm.on 'submit', (e) =>
                    e.preventDefault()
                    $createPostForm.ajaxSubmit
                        beforeSubmit: ->
                            $createPostSubmitError.text ''
                            $createPostSubmitButton.prop 'disabled', yes
                        clearForm: yes
                        dataType: 'json'
                        xhrFields:
                            withCredentials: yes
                        headers: { 'X-CSRF-Token': @identity.token }
                        success: (responseText, textStatus, jqXHR) ->
                            $createPostModal.modal 'hide'
                        error: (jqXHR, textStatus, errorThrown) ->
                            if jqXHR.responseJSON?
                                $createPostSubmitError.text jqXHR.responseJSON
                            else
                                $createPostSubmitError.text 'Unknown error. Please try again later.'
                        complete: ->
                            $createPostSubmitButton.prop 'disabled', no

        initEditPostModal: ->
            $buttonEditPost = @$main.find 'button[data-action="edit-post"]'
            if $buttonEditPost.length
                $editPostModal = $ '#edit-post-modal'
                $editPostModal.modal
                    show: no

                $editPostSubmitError = $editPostModal.find '.submit-error > p'
                $editPostSubmitButton = $editPostModal.find 'button[data-action="complete-edit-post"]'
                $editPostForm = $editPostModal.find 'form'
                $editPostForm.parsley()

                $editPostSubmitButton.on 'click', (e) ->
                    $editPostForm.trigger 'submit'

                $editPostTablist = $ '#edit-post-tablist'
                $editPostTabData = $editPostTablist.find 'a[href="#edit-post-data"]'
                $editPostTabPreview = $editPostTablist.find 'a[href="#edit-post-preview"]'

                $editPostTitle = $ '#edit-post-title'
                $editPostDescription = $ '#edit-post-description'

                $editPostPreview = $ '#edit-post-preview'

                $editPostTabData.tab()
                $editPostTabPreview.tab()

                $editPostTabPreview.on 'show.bs.tab', (e) ->
                    md = new MarkdownIt()
                    options =
                        title: $editPostTitle.val()
                        description: md.render $editPostDescription.val()
                        updatedAt: moment(new Date()).format 'lll'

                    $editPostPreview.html renderTemplate 'post-simplified-partial', options

                $editPostModal.on 'show.bs.modal', (e) =>
                    $editPostTabData.tab 'show'
                    postId = parseInt $(e.relatedTarget).data('post-id'), 10
                    post = _.findWhere @posts, id: postId

                    $editPostForm.attr 'action', "#{metadataStore.getMetadata 'domain-api' }/post/#{postId}/update"
                    $editPostTitle.val post.title
                    $editPostDescription.val post.description
                    $editPostSubmitError.text ''

                $editPostModal.on 'shown.bs.modal', (e) ->
                    $editPostTitle.focus()

                $editPostForm.on 'submit', (e) =>
                    e.preventDefault()
                    $editPostForm.ajaxSubmit
                        beforeSubmit: ->
                            $editPostSubmitError.text ''
                            $editPostSubmitButton.prop 'disabled', yes
                        clearForm: yes
                        dataType: 'json'
                        xhrFields:
                            withCredentials: yes
                        headers: { 'X-CSRF-Token': @identity.token }
                        success: (responseText, textStatus, jqXHR) ->
                            $editPostModal.modal 'hide'
                        error: (jqXHR, textStatus, errorThrown) ->
                            if jqXHR.responseJSON?
                                $editPostSubmitError.text jqXHR.responseJSON
                            else
                                $editPostSubmitError.text 'Unknown error. Please try again later.'
                        complete: ->
                            $editPostSubmitButton.prop 'disabled', no


        present: ->
            @$main = $ '#main'

            dataStore.getIdentity (err, identity) =>
                if err?
                    @$main.html renderTemplate 'internal-error'
                    navigationBar.present()
                else
                    @identity = identity
                    @$main.html renderTemplate 'news-view', identity: identity
                    navigationBar.present
                        identity: identity
                        active: 'news'

                    $section = @$main.find 'section'

                    dataStore.getPosts (err, posts) =>
                        if err?
                            $section.html $('<p></p>').addClass('lead text-danger').text err
                        else
                            @posts = posts
                            @renderPosts()

                            if _.contains ['admin', 'manager'], identity.role
                                @initCreatePostModal()
                                @initRemovePostModal()
                                @initEditPostModal()

                    if dataStore.supportsRealtime()
                        dataStore.connectRealtime()

                        @onCreatePost = (e) =>
                            data = JSON.parse e.data
                            post =
                                id: data.id
                                title: data.title
                                description: data.description
                                createdAt: new Date data.createdAt
                                updatedAt: new Date data.updatedAt

                            @posts.push post
                            @renderPosts()

                        dataStore.getRealtimeProvider().addEventListener 'createPost', @onCreatePost

                        @onUpdatePost = (e) =>
                            data = JSON.parse e.data
                            post = _.findWhere @posts, id: data.id
                            post.title = data.title
                            post.description = data.description
                            post.updatedAt = new Date data.updatedAt
                            @renderPosts()

                        dataStore.getRealtimeProvider().addEventListener 'updatePost', @onUpdatePost

                        @onRemovePost = (e) =>
                            post = JSON.parse e.data
                            ndx = _.findIndex @posts, id: post.id

                            if ndx > -1
                                @posts.splice ndx, 1
                                @renderPosts()

                        dataStore.getRealtimeProvider().addEventListener 'removePost', @onRemovePost


        dismiss: ->
            if dataStore.supportsRealtime()
                if @onCreatePost?
                    dataStore.getRealtimeProvider().removeEventListener 'createPost', @onCreatePost
                    @onCreatePost = null
                if @onRemovePost?
                    dataStore.getRealtimeProvider().removeEventListener 'removePost', @onRemovePost
                    @onRemovePost = null
                if @onUpdatePost?
                    dataStore.getRealtimeProvider().removeEventListener 'updatePost', @onUpdatePost
                    @onUpdatePost = null
                dataStore.disconnectRealtime()

            @$main.empty()
            @$main = null
            @identity = null
            @posts = []

            navigationBar.dismiss()

    new NewsView()
