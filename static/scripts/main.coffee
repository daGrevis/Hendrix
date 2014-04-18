Dom = React.DOM

delay = (ms, fn) -> setTimeout fn, ms

getSegments = ->
    uri = location.hash[2..]
    uri.split("/")

generateUuid4 = ->
    # http://stackoverflow.com/a/2117523/458610
    "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace /[xy]/g, (c) ->
        r = Math.random() * 16 | 0
        v = (if c is "x" then r else (r & 0x3 | 0x8))
        v.toString 16

sum = (coll) -> _.reduce coll, ((a, x) -> a + x), 0

PEER_KEY = "3wlgt1tsm69u23xr"
BASE_URL = location.origin + location.pathname

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

        idForDiv = props.id
        props.id = generateUuid4()

        (Dom.div id: idForDiv, className: "form-group",
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
        (Dom.nav id: "navbar", className: "navbar navbar-default",
            (Dom.div className: "navbar-header",
                (Dom.a className: "navbar-brand", @props.brandName)),
            (Dom.ul className: "nav navbar-nav",
                _.map @props.navbarItems, (item) ->
                    [url, title] = item
                    (Dom.li null,
                        (Dom.a href: "##{ url }", title))))

Footer = React.createClass
    displayName: "Footer"

    render: ->
        (Dom.div id: "footer",
            (Dom.p null,
                (Dom.a href: "https://github.com/daGrevis/Hendrix", "Hendrix on GitHub"))
            (Dom.p null,
                (Dom.a href: "https://twitter.com/dagrevis", "Made by @daGrevis")))

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

        classNamesForLi = ["media"]
        if @props.isRepeated
            classNamesForLi.push "repeated-message"

        (Dom.li className: classNamesForLi.join(" "),
            (Dom.a className: "pull-left avatar",
                (Dom.img width: 32, height: 32, src: "http://avatars.io/email/#{ @props.email }?size=small", className: "media-object"))
            (Dom.div className: "media-body",
                (Dom.h4 className: "media-heading displayName", @props.displayName)
                (Dom.span dangerouslySetInnerHTML: {__html: content})))

ChatMessages = React.createClass
    displayName: "ChatMessages"

    componentDidUpdate: ->
        $chatMessages = document.getElementById "chat-messages"
        $chatMessages.scrollTop = $chatMessages.scrollHeight

        height = window.innerHeight - 400
        ($chatMessages.style).height = "#{ height }px"

    render: ->
        (Dom.ul id: "chat-messages", className: "media-list",
            peerId = false
            _.map @props.messages, (message) =>
                if peerId == message.peerId
                    isRepeated = true
                else
                    isRepeated = false
                peerId = message.peerId
                (ChatMessage content: message.content, displayName: message.displayName, email: message.email, isRepeated: isRepeated))

ChatForm = React.createClass
    mixins: [React.addons.LinkedStateMixin]

    displayName: "ChatForm"

    getInitialState: ->
        message: ""
        keysPressed:
            "Shift": false
            "Enter": false

    render: ->
        (Dom.form id: "chat-form", onKeyDown: @keyDown, onKeyUp: @keyUp,
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

ChatLink = React.createClass
    displayName: "ChatLink"

    render: ->
        if not @props.peerIdForFounder
            return Noop()

        (Input id: "chat-link", label: "Chat Link", readOnly: true, value: @getLink())

    getLink: ->
        "#{ BASE_URL }#/chat/#{ @props.peerIdForFounder}"

Chat = React.createClass
    displayName: "Chat"

    getInitialState: ->
        peerIdForFounder: null
        messages: []

    componentWillMount: ->
        peerIdForFounder = getSegments()[1]
        isFounder = not peerIdForFounder?

        peer = new Peer(key: PEER_KEY)

        @connections = []

        peer.on "error", (error) =>
            console.log error

            @props.addAlert type: "danger", "Something went terribly wrong! See console."

        peer.on "open", (peerId) =>
            @peerId = peer.id

            if isFounder
                peerIdForFounder = peer.id
                @setState peerIdForFounder: peerIdForFounder

                peer.on "connection", (connection) =>
                    connection.on "open", =>
                        if @connections.length
                            peerIds = _.map @connections, (connection) -> connection.peer
                            connection.send type: "newConnection", peerIds: peerIds

                        @connections.push connection
                        @listenForMessage connection

                        @showAlertAboutNewConnection()

            if not isFounder
                @setState peerIdForFounder: peerIdForFounder

                connection = peer.connect peerIdForFounder

                connection.on "open", =>
                    @connections.push connection
                    @listenForMessage connection

                    connection.on "data", (data) =>
                        if data.type == "newConnection"
                            _.forEach data.peerIds, (peerId) =>
                                connection = peer.connect peerId

                                do (connection) =>
                                    connection.on "open", =>
                                        @connections.push connection
                                        @listenForMessage connection

                connection.on "close", =>
                    @props.addAlert type: "warning", "Founder left the channel!"

                peer.on "connection", (connection) =>
                    connection.on "open", =>
                        @connections.push connection
                        @listenForMessage connection

                        @showAlertAboutNewConnection()

    render: ->
        (Dom.div null,
            (ChatLink peerIdForFounder: @state.peerIdForFounder),
            (ChatMessages messages: @state.messages),
            (ChatForm sendMessage: @sendMessage))

    sendMessage: (message) ->
        messages = @state.messages
        message.peerId = @peerId
        messages.push message
        @setState messages: messages

        data =
            type: "message"
            message: message

        _.forEach @connections, (connection) ->
            connection.send data

    listenForMessage: (connection) ->
        connection.on "data", (data) =>
            if data.type == "message"

                messages = @state.messages
                messages.push data.message
                @setState messages: messages

    showAlertAboutNewConnection: ->
        @props.addAlert type: "info", "Someone joined the channel!"

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
    [/chat\/.+/, Chat]
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
        (Dom.div className: "container",
            (Navbar brandName: @props.brandName, navbarItems: @props.navbarItems),
            (@state.alert)
            (@state.currentComponent)
            (Footer()))

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
