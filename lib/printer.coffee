{CompositeDisposable} = require 'atom'
_ = null

module.exports = AtomPrinter =
  atomPrinterView: null
  modalPanel: null
  subscriptions: null

  activate: (state) ->
    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'printer:print': => @print()

  deactivate: ->
    @subscriptions.dispose()

  serialize: ->

  print: ->
    _ ?= require 'lodash'

    iframe = document.createElement('iframe')

    iframe.style.visibility = 'hidden'
    iframe.style.position = 'fixed'
    iframe.style.right = 0
    iframe.style.bottom = 0

    document.body.appendChild(iframe)

    close = ->
      document.body.removeChild(iframe)

    content = iframe.contentWindow

    content.onbeforeunload = close
    content.onafterprint = close
    container = content.document.createElement('pre')
    root = container.createShadowRoot()
    root.innerHTML = @getEditorHTML()
    content.document.body.appendChild(container)
    content.print()

  getEditorHTML: ->
    editor = atom.workspace.getActiveTextEditor()
    text = editor.getText()
    grammar = editor.getGrammar()

    lines = grammar.tokenizeLines(text)
    scopeStack = []
    html = @getThemeHTML()

    for line in lines
      for token in line
        html += @updateScopeStack(scopeStack, token.scopes)
        html += token.getValueAsHtml(hasIndentGuide: false)
      html += "\n"

    console.log html
    html

  getThemeHTML: ->
    themes = atom.themes.getActiveThemes()
    syntaxTheme = _.find themes, (theme) -> theme.metadata.theme is 'syntax'
    "<style>#{sheet[1] for sheet in syntaxTheme.stylesheets}</style>"

  updateScopeStack: (scopeStack, desiredScopeDescriptor) ->
    html = ""

    # Find a common prefix
    for scope, i in desiredScopeDescriptor
      break unless scopeStack[i] is desiredScopeDescriptor[i]

    # Pop scopeDescriptor until we're at the common prefx
    until scopeStack.length is i
      html += @popScope(scopeStack)

    # Push onto common prefix until scopeStack equals desiredScopeDescriptor
    for j in [i...desiredScopeDescriptor.length]
      html += @pushScope(scopeStack, desiredScopeDescriptor[j])

    html

  popScope: (scopeStack) ->
    scopeStack.pop()
    "</span>"

  pushScope: (scopeStack, scope) ->
    scopeStack.push(scope)
    "<span class=\"#{scope.replace(/\.+/g, ' ')}\">"
