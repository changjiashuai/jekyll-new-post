{View, EditorView} = require 'atom'
path = require 'path'
fs = require 'fs-plus'

module.exports =
class JekyllNewPostView extends View
  @content: ->
    @div class: 'jekyll-new-post overlay from-top', =>
      @label "Post Title", class: 'icon icon-file-add', outlet: 'promptText'
      @subview 'miniEditor', new EditorView(mini: true)
      @div class: 'error-message', outlet: 'errorMessage'

  initialize: (serializeState) ->
    atom.workspaceView.command "jekyll-new-post:toggle", => @toggle()
    @on 'core:confirm', => @onConfirm(@miniEditor.getText())
    @on 'core:cancel', => @destroy()

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @detach()

  toggle: ->
    console.log "Creating a new Post (jekyll-new-post)"
    if @hasParent()
      @detach()
    else
      atom.workspaceView.append(this)
      @miniEditor.focus()

  showError: (error)->
    @errorMessage.text(error)
    @flashError() if error

  fileContents:(title, dateString)->
    return '---\r\nlayout: post\r\ntitle: "' + title + '"\r\ndate: ' + dateString + '\r\n---'

  onConfirm: (title) ->
    currentTime = new Date()
    dateString = currentTime.getFullYear() + "-" + ("0" + (currentTime.getMonth() + 1)).slice(-2) + "-" + ("0" + currentTime.getDate()).slice(-2)

    titleName = title.toLowerCase().replace(/[^\w\s]|_/g, "").replace(RegExp(" ", 'g'),"-")
    fileName = dateString + "-" + titleName
    relativePath = "_posts/" + fileName + ".markdown"
    endsWithDirectorySeparator = /\/$/.test(relativePath)
    pathToCreate = atom.project.resolve(relativePath)
    return unless pathToCreate

    try
      if fs.existsSync(pathToCreate)
        @showError("'#{pathToCreate}' already exists.")
      else
        if endsWithDirectorySeparator
          @showError("File names must not end with a '/' character.")
        else
          fs.writeFileSync(pathToCreate, @fileContents(title, dateString))
          atom.project.getRepo()?.getPathStatus(pathToCreate)
          atom.workspaceView.open(pathToCreate)
          @destroy()
    catch error
      @showError("#{error.message}.")
