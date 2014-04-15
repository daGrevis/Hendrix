Dom = React.DOM

delay = (ms, fn) -> setTimeout fn, ms

getSegments = ->
    uri = location.hash[2..]
    uri.split("/")

PEER_KEY = "3wlgt1tsm69u23xr"

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

Chat = React.createClass
    displayName: "Foo"

    getInitialState: ->
        messages: []

    connectionsToPeerIds: (connections) ->
        _.map connections, (connection) => connection.peer

    componentWillMount: ->
        who = getSegments()[1]
        console.log "who: #{ who }"

        peer = new Peer who, key: PEER_KEY, debug: 2
        console.log "new Peer()"

        @connections = []

        peer.on "error", (error) =>
            alert error.type

        peer.on "open", (peerId) =>
            console.log "peer.on"
            console.log "peerId: #{ peerId }"

            if who == "x"
                console.log "acting as #{ who }, host"

                peer.on "connection", (connection) =>
                    console.log "new connection"
                    console.log "peer #{ connection.peer } just connected to host #{ peerId }"

                    @connections.push connection

                    peerIds = @connectionsToPeerIds @connections

                    console.log "connected peers: #{ peerIds }"

                    _.forEach @connections, (c) =>
                        c.on "open", =>
                            console.log "sending connections to #{ c.peer }"

                            c.send type: "newConnection", peerIds: peerIds

                    connection.on "data", (data) =>
                        if data.type == "message"
                            messages = @state.messages
                            messages.push data.message
                            @setState messages: messages

            if who != "x"
                console.log "acting as #{ who }, normal peer"

                connection = peer.connect "x"
                console.log "connecting to x, host"

                @connections.push connection

                connection.on "error", (error) =>
                    alert error

                connection.on "open", =>
                    console.log "connection to #{ connection.peer } open"

                    connection.on "data", (data) =>
                        if data.type == "message"
                            messages = @state.messages
                            messages.push data.message
                            @setState messages: messages

                    connection.on "data", (data) =>
                        if data.type == "newConnection"
                            peerIds = data.peerIds
                            peerIds = _.filter peerIds, (peerId) -> peerId != who

                            console.log "new connections without my connection: #{ peerIds }"

                            _.forEach peerIds, (peerId) =>
                                console.log "connecting to #{ peerId }"

                                connection = peer.connect peerId

                                connection.on "error", (error) =>
                                    alert error.type

                                connection.on "open", =>
                                    console.log "connection to #{ connection.peer } open"

                                    @connections.push connection

                                    connection.on "data", (data) =>
                                        console.log "RECEIVED MESSAGE FROM NEW PEER"
                                        if data.type == "message"
                                            messages = @state.messages
                                            messages.push data.message
                                            @setState messages: messages

    render: ->
        (Dom.div null,
            (ChatMessages messages: @state.messages),
            (ChatForm sendMessage: @sendMessage))

    sendMessage: (message) ->
        messages = @state.messages
        messages.push message
        @setState messages: messages

        data =
            type: "message"
            message: message

        _.forEach @connections, (c) ->
            console.log "sending message to #{ c.peer }"
            c.send data

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
    [/chat\/\w+/, Chat]
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
            (Navbar brandName: @props.brandName, navbarItems: @props.navbarItems),
            (@state.alert)
            (@state.currentComponent))

    addAlert: (props, children) ->
        @setState alert: Alert(props, children)

        delay @props.alertDelay, =>
            @setState alert: Noop()

options =
    routes: routes
    defaultRoute: "/chat"
    brandName: "Hendrix"
    navbarItems: navbarItems
    alertDelay: 10 * 1000
mountNode = document.getElementById("react")

React.renderComponent Root(options), mountNode
