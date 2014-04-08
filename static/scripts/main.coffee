BASE_URL = "http://127.0.0.1:8000"
CHAT_SLUG = "hello-world"

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

ChatNew = React.createClass
    displayName: "ChatNew"

    componentWillMount: ->
        router.setRoute "/chat/#{ CHAT_SLUG }"

    render: ->
        link = "#{ BASE_URL }/#/chat/#{ CHAT_SLUG }"

        (Dom.div null,
            (Dom.form null,
                (Input id: "link", label: "Link to the chat", readOnly: true, value: link)),
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
