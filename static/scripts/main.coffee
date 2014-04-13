Dom = React.DOM

BASE_URL = "http://127.0.0.1:8000"

peer = new Peer key: "3wlgt1tsm69u23xr"

peer.on "open", (peer_id) ->
    window.peer_id = peer_id
    initApp()

peer.on "connection", (connection) ->
    window.connection = connection
    router.setRoute "/chat"

peer.on "error", (error) ->
    alert error.message

avatars = [
    "https://minotar.net/avatar/clone1018/64.png",
    "https://minotar.net/avatar/citricsquid/64.png",
    "https://minotar.net/avatar/Raitsui/64.png",
    "https://minotar.net/avatar/runforthefinish/64.png",
    "https://minotar.net/avatar/NoMercyJon/64.png",
    "https://minotar.net/avatar/Nautika/64.png",
    "https://minotar.net/avatar/Notch/64.png",
    "https://minotar.net/avatar/NiteAngel/64.png",
    "https://minotar.net/avatar/S1NZ/64.png",
    "https://minotar.net/avatar/drupal/64.png",
    "https://minotar.net/avatar/ez/64.png",
]

getAvatarLink = ->
    avatars[_.random avatars.length]

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

Index = React.createClass
    displayName: "Index"

    render: ->
        (Dom.p null, "Hello from Index!")

ChatMessage = React.createClass
    displayName: "ChatMessage"

    render: ->
        (Dom.li className: "media",
            (Dom.a className: "pull-left",
                (Dom.img width: 64, height: 64, src: getAvatarLink(), className: "media-object")),
            (Dom.div className: "media-body", @props.message))

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

                @props.send @state.message

                @setState message: ""

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
            (ChatForm send: @send))

    addMessage: (message) ->
        messages = @state.messages
        messages.push message
        @setState messages: messages

    send: (message) ->
        @addMessage message

        connection.send message


Connect = React.createClass
    mixins: [React.addons.LinkedStateMixin]

    displayName: "Connect"

    getInitialState: ->
        other_id: ""

    render: ->
        (Dom.form onSubmit: @connect,
            (Input id: "your_id", label: "Your ID", readOnly: true, value: peer_id),
            (Input id: "other_id", label: "Other ID", valueLink: @linkState "other_id"),
            (ReactBootstrap.Button bsStyle: "primary", type: "submit",
                "Connect"))

    connect: (event) ->
        event.preventDefault()

        if not @state.other_id
            alert "You can't connect to nothing!"
            return

        window.connection = peer.connect @state.other_id
        connection.on "open", ->
            router.setRoute "/chat"

initApp = ->

    routes = [
        ["/", Index()],
        ["/connect", Connect()]
        ["/chat", Chat()]
    ]

    navItems = [
        ["/", "Index"],
        ["/connect", "Connect"]
    ]

    window.router = Router()

    Root = React.createClass
        displayName: "Root"

        getInitialState: ->
            currentComponent: Index()

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
    React.renderComponent Root(routes: routes, navItems: navItems, defaultRoute: "/"), mountNode
