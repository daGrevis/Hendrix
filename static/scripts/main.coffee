Dom = React.DOM

delay = (ms, fn) -> setTimeout fn, ms

getSegments = ->
    uri = location.hash[2..]
    uri.split("/")

PEER_KEY = "3wlgt1tsm69u23xr"
BASE_URL = "#{ location.protocol }//#{ location.host }"

Noop = React.createClass
    displayName: "Noop"

    render: ->
        (Dom.span null)

Input = React.createClass
    displayName: "Input"

    render: ->
        defaultProps =
            type: "text"
            className: "form-control"
        props = _.extend defaultProps, @props

        (Dom.div className: "form-group",
            (Dom.label htmlFor: props.id, props.label)
            (Dom.input props))

Textarea = React.createClass
    displayName: "Textarea"

    render: ->
        defaultProps =
            cols: 80
            rows: 4
            className: "form-control"
        props = _.extend defaultProps, @props

        (Dom.textarea props)

Navbar = React.createClass
    displayName: "Navbar"

    render: ->
        (Dom.nav className: "navbar navbar-default",
            (Dom.div className: "navbar-header",
                (Dom.a className: "navbar-brand", @props.brandName)),
            (Dom.ul className: "nav navbar-nav",
                _.map @props.navbarItems, (item) ->
                    [url, title] = item
                    (Dom.li null,
                        (Dom.a href: "##{ url }", title))))

Alert = React.createClass
    displayName: "Alert"

    render: ->
        defaultProps =
            type: "success"
            className: "alert"
        props = _.extend defaultProps, @props

        props.className = "#{ props.className } alert-#{ props.type }"

        delete props.type

        (Dom.div props,
            @props.children)

ChatMessage = React.createClass
    displayName: "ChatMessage"

    render: ->
        content = marked @props.content

        (Dom.li className: "media",
            (Dom.a className: "pull-left",
                (Dom.img width: 32, height: 32, src: "http://avatars.io/email/#{ @props.email }?size=small", className: "media-object")),
            (Dom.div className: "media-body",
                (Dom.h4 className: "media-heading", @props.displayName),
                (Dom.span dangerouslySetInnerHTML: {__html: content})))

ChatMessages = React.createClass
    displayName: "ChatMessages"

    componentDidUpdate: ->
        $chatMessages = document.getElementById("chat-messages")
        $chatMessages.scrollTop = $chatMessages.scrollHeight

    render: ->
        (Dom.ul id: "chat-messages", className: "media-list",
            _.map @props.messages, (message) ->
                (ChatMessage content: message.content, displayName: message.displayName, email: message.email, email: message.email))

ChatForm = React.createClass
    mixins: [React.addons.LinkedStateMixin]

    displayName: "ChatForm"

    getInitialState: ->
        message: ""
        keysPressed:
            "Shift": false
            "Enter": false

    render: ->
        (Dom.form onKeyDown: @keyDown, onKeyUp: @keyUp,
            (Textarea id: "message", placeholder: "Type a message here...", valueLink: @linkState "message"))

    keyDown: (event) ->
        if event.key in _.keys @state.keysPressed
            keysPressed = @state.keysPressed
            keysPressed[event.key] = true
            @setState keysPressed: keysPressed

            if not keysPressed["Shift"] and keysPressed["Enter"]
                if not @state.message
                    alert "You can't send nothing!"
                    return

                message =
                    displayName: store.get "displayName"
                    email: store.get "email"
                    content: @state.message
                @props.sendMessage message

                @setState message: ""

                event.preventDefault()

    keyUp: (event) ->
        if event.key in _.keys @state.keysPressed
            keysPressed = @state.keysPressed
            keysPressed[event.key] = false
            @setState keysPressed: keysPressed

ChatConnected = React.createClass
    displayName: "ChatConnected"

    getInitialState: ->
        messages: []

    componentDidMount: ->
        (@props.connection).on "data", (message) =>
            @addMessage message

    render: ->
        (Dom.div null,
            (ChatMessages messages: @state.messages),
            (ChatForm sendMessage: @sendMessage))

    addMessage: (message) ->
        messages = @state.messages
        messages.push message
        @setState messages: messages

    sendMessage: (message) ->
        @addMessage message

        (@props.connection).send message


ChatDisconnected = React.createClass
    mixins: [React.addons.LinkedStateMixin]

    displayName: "ChatDisconnected"

    getInitialState: ->
        otherId: ""

    render: ->
        chatLink = "#{ BASE_URL }/#/chat/#{ @props.peerId }"

        (Dom.div null,
            (Dom.form null,
                (Input id: "link", label: "Chat Link", readOnly: true, value: chatLink)
            ))

Chat = React.createClass
    displayName: "Chat"

    getInitialState: ->
        currentComponent: Noop()

    componentWillMount: ->
        @peer = new Peer key: PEER_KEY

        @peer.on "open", (peerId) =>
            @peerId = peerId

            otherPersonPeerId = getSegments()[1]

            if otherPersonPeerId?
                connection = @peer.connect otherPersonPeerId
                @onConnect()
                @onClose connection

                @setState currentComponent: ChatConnected(connection: connection)
            else
                @setState currentComponent: ChatDisconnected(peerId: @peerId)

                @peer.on "connection", (connection) =>
                    @onConnect()
                    @onClose connection

                    @setState currentComponent: ChatConnected(connection: connection)

    componentDidMount: ->
        # TODO: This should be in `componentWillMount`.
        @peer.on "error", =>
            @props.addAlert type: "danger",
                (Dom.span null,
                    (Dom.strong null, "Oh snap! "),
                    (Dom.span null, "Something went terribly wrong with WebRTC."))

    render: ->
        @state.currentComponent

    onConnect: ->
        @props.addAlert type: "warning",
            (Dom.span null,
                (Dom.strong null, "Well done! "),
                (Dom.span null, "You are connected now."))

    onClose: (connection) ->
        connection.on "close", =>
            @props.addAlert type: "warning",
                (Dom.span null,
                    (Dom.strong null, "Warning! "),
                    (Dom.span null, "The other person just disconnected."))
            @setState currentComponent: ChatDisconnected(peerId: @peerId)

Settings = React.createClass
    mixins: [React.addons.LinkedStateMixin]

    displayName: "Settings"

    getInitialState: ->
        displayName: store.get("displayName")
        email: store.get("email")

    render: ->
        (Dom.form onSubmit: @save,
            (Input id: "displayName", label: "Display Name", valueLink: @linkState "displayName"),
            (Input id: "email", label: "Email (for Gravatar)", valueLink: @linkState "email"),
            (Dom.button className: "btn btn-success", type: "submit",
                "Save"))

    save: (event) ->
        event.preventDefault()

        if @state.displayName
            store.set "displayName", @state.displayName
        if @state.email
            store.set "email", @state.email

        @props.addAlert type: "success", "Changes saved!"

routes = [
    ["/chat", Chat]
    [/chat\/[a-z0-9]+/, Chat]
    ["/settings", Settings]
]

navbarItems = [
    ["/chat", "Chat"]
    ["/settings", "Settings"]
]

# TODO: Move this to `Root` component.
window.router = Router()

Root = React.createClass
    displayName: "Root"

    getInitialState: ->
        currentComponent: Noop()
        alert: Noop()

    componentDidMount: ->
        _.forEach @props.routes, (route) =>
            [url, component] = route

            router.on url, =>
                @setState currentComponent: component(addAlert: @addAlert)
        router.init @props.defaultRoute

    render: ->
        (Dom.div null,
            (Navbar brandName: "Peer Chat", navbarItems: @props.navbarItems),
            (@state.alert)
            (@state.currentComponent))

    addAlert: (props, children) ->
        @setState alert: Alert(props, children)

        delay @props.alertDelay, =>
            @setState alert: Noop()

options =
    routes: routes
    defaultRoute: "/chat"
    navbarItems: navbarItems
    alertDelay: 10 * 1000
mountNode = document.getElementById("react")

React.renderComponent Root(options), mountNode
