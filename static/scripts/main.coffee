BASE_URL = "http://127.0.0.1:8000"
CHAT_SLUG = "hello-world"

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

# uuid4 = ->
#     # From http://stackoverflow.com/a/2117523/458610.
#     "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace /[xy]/g, (c) ->
#         r = Math.random() * 16 | 0
#         v = (if c is "x" then r else (r & 0x3 | 0x8))
#         v.toString 16

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
    mixins: [React.addons.LinkedStateMixin]

    displayName: "Textarea"

    getInitialState: ->
        message: ""

    componentDidMount: ->
        new Behave textarea: document.getElementById @props.id

    render: ->
        defaultProps =
            valueLink: @linkState "message"
            cols: 80
            rows: 4
            className: "form-control"
        props = _.extend defaultProps, @props

        (Dom.textarea props)

Dom = React.DOM

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

    getInitialState: ->
        messages: [
            "foo",
            "bar",
            "baz"
        ]

    render: ->
        (Dom.ul className: "media-list",
            _.map @state.messages, (message) ->
                (ChatMessage message: message))

ChatNew = React.createClass
    displayName: "ChatNew"

    componentWillMount: ->
        router.setRoute "/chat/#{ CHAT_SLUG }"

    render: ->
        link = "#{ BASE_URL }/#/chat/#{ CHAT_SLUG }"

        (Dom.div null,
            (Dom.form null,
                (Input id: "link", label: "Link to the chat", readOnly: true, value: link)),
            (ChatMessages null),
            (Dom.form null,
                (Textarea id: "message", placeholder: "Type a message here...")))

routes = [
    ["/", Index()],
    [/chat\/([\w-_]+)?/, ChatNew()]
]

navItems = [
    ["/", "Index"],
    ["/chat/", "Chat"]
]

router = Router()

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
