Dom = React.DOM

delay = (ms, fn) -> setTimeout fn, ms

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
        $("#chat-messages").scrollTop($("#chat-messages").height())

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
        (Dom.form onSubmit: @save,
            (Input id: "displayName", label: "Display Name", valueLink: @linkState "displayName"),
            (Input id: "email", label: "Email (for Gravatar)", valueLink: @linkState "email"),
            (ReactBootstrap.Button bsStyle: "success", type: "submit",
                "Save"))

    save: (event) ->
        event.preventDefault()

        if @state.displayName
            store.set "displayName", @state.displayName
        if @state.email
            store.set "email", @state.email

        @props.addAlert type: "success", "Changes saved!"

initApp = ->

    routes = [
        ["/connect", Connect]
        ["/chat", Chat]
        ["/settings", Settings]
    ]

    navbarItems = [
        ["/connect", "Connect"]
        ["/settings", "Settings"]
    ]

    window.router = Router()

    Root = React.createClass
        displayName: "Root"

        getInitialState: ->
            currentComponent: Connect()
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

            delay 4 * 1000, =>
                @setState alert: Noop()

    mountNode = document.getElementById("react")
    React.renderComponent Root(routes: routes, defaultRoute: "/connect", navbarItems: navbarItems), mountNode
