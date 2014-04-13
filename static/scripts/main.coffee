Dom = React.DOM

BASE_URL = "http://127.0.0.1:8000"

peer = new Peer key: "3wlgt1tsm69u23xr"

peer.on "open", (peerId) ->
    window.peerId = peerId
    initApp()

peer.on "connection", (connection) ->
    window.connection = connection
    router.setRoute "/chat"

peer.on "error", (error) ->
    alert error.message

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

ChatMessage = React.createClass
    displayName: "ChatMessage"

    render: ->
        email = store.get "email"
        displayName = store.get "displayName"

        (Dom.li className: "media",
            (Dom.a className: "pull-left",
                (Dom.img width: 64, height: 64, src: "http://avatars.io/email/#{ email }?size=medium", className: "media-object")),
            (Dom.div className: "media-body",
                (Dom.h4 className: "media-heading", displayName),
                @props.message))

ChatMessages = React.createClass
    displayName: "ChatMessages"

    render: ->
        (Dom.ul className: "media-list",
            _.map @props.messages, (message) ->
                (ChatMessage message: message))

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

            if keysPressed["Shift"] and keysPressed["Enter"]
                if not @state.message
                    alert "You can't send nothing!"
                    return

                @props.sendMessage @state.message

                @setState message: ""

                event.preventDefault()

    keyUp: (event) ->
        if event.key in _.keys @state.keysPressed
            keysPressed = @state.keysPressed
            keysPressed[event.key] = false
            @setState keysPressed: keysPressed

Chat = React.createClass
    displayName: "Chat"

    getInitialState: ->
        messages: []

    componentWillMount: ->
        if not connection?
            router.setRoute "/connect"
            return

    componentDidMount: ->
        connection.on "data", (message) =>
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

        connection.send message


Connect = React.createClass
    mixins: [React.addons.LinkedStateMixin]

    displayName: "Connect"

    getInitialState: ->
        otherId: ""

    render: ->
        (Dom.form onSubmit: @connect,
            (Input id: "yourId", label: "Your ID", readOnly: true, value: peerId),
            (Input id: "otherId", label: "Other ID", valueLink: @linkState "otherId"),
            (ReactBootstrap.Button bsStyle: "primary", type: "submit",
                "Connect"))

    connect: (event) ->
        event.preventDefault()

        if not @state.otherId
            alert "You can't connect to nothing!"
            return

        window.connection = peer.connect @state.otherId
        connection.on "open", ->
            router.setRoute "/chat"

Settings = React.createClass
    mixins: [React.addons.LinkedStateMixin]

    displayName: "Settings"

    getInitialState: ->
        displayName: store.get("displayName")
        email: store.get("email")

    render: ->
        (Dom.form onSubmit: @saveSettings,
            (Input id: "displayName", label: "Display Name", valueLink: @linkState "displayName"),
            (Input id: "email", label: "Email (for Gravatar)", valueLink: @linkState "email"),
            (ReactBootstrap.Button bsStyle: "success", type: "submit",
                "Save Settings"))

    saveSettings: (event) ->
        event.preventDefault()

        if @state.displayName
            store.set "displayName", @state.displayName
        if @state.email
            store.set "email", @state.email

initApp = ->

    routes = [
        ["/connect", Connect()]
        ["/chat", Chat()]
        ["/settings", Settings()]
    ]

    navItems = [
        ["/connect", "Connect"]
        ["/settings", "Settings"]
    ]

    window.router = Router()

    Root = React.createClass
        displayName: "Root"

        getInitialState: ->
            currentComponent: Connect()

        componentDidMount: ->
            _.forEach @props.routes, (route) =>
                [url, component] = route

                router.on url, =>
                    @setState currentComponent: component
            router.init @props.defaultRoute


        render: ->
            (Dom.div null,
                (ReactBootstrap.Nav bsStyle: "pills",
                    _.map @props.navItems, (item) ->
                        [url, title] = item

                        (ReactBootstrap.NavItem href: "##{ url }", title))

                (@state.currentComponent))

    mountNode = document.getElementsByClassName("container")[0]
    React.renderComponent Root(routes: routes, navItems: navItems, defaultRoute: "/connect"), mountNode
