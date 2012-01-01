root = global ? window

root.XML2JSON =
  _parseAttributes: (xml, json, attr2child) ->
    if attr2child
      json[attr.nodeName] = attr.nodeValue for attr in xml.attributes
    else
      json["@attributes"] = {}
      json["@attributes"][attr.nodeName] = attr.nodeValue for attr in xml.attributes
    return json
  
  _parseChildren: (xml, json, attr2child) ->
    for childNode in xml.childNodes
      child = this.parse childNode, attr2child
      if childNode.nodeType is 1
        # Child nodes.
        name = childNode.localName
        if json[name]
          # Duplicate name, so we make it an array.
          if not (json[name] instanceof Array)
            json[name] = [json[name]]
          json[name][json[name].length] = child
        else
          json[name] = child
      else if childNode.nodeType is 3
        # Child text. We should check if it's empty and discard empty text.
        name = "@text"
        text = child.replace(/^\s+/, '').replace(/\s+$/, '')
        if text isnt ""
          json[name] = text

      # We treat the child node of a root node with no attributes and only a 
      # text child node to be just the text itself.
      if (not xml.hasAttributes() || (xml.hasAttributes() && xml.attributes.length == 1 && xml.attributes[0].nodeName == 'type')) and xml.childNodes.length is 1 and json["@text"]
        json = json["@text"]
    return json

  parse: (xml, attr2child = false) ->
    ###
    # @param attr2child - Convert attributes to children.
    ###
    if typeof xml is "string"
      xml = new DOMParser().parseFromString xml, "text/xml"

    json = {}
    if xml.nodeType is 9  # Root document.
      name = xml.childNodes[0].localName
      json[name] = this.parse xml.childNodes[0], attr2child
      return json
    else if xml.nodeType is 1  # Element.
      if xml.hasAttributes()
        json = this._parseAttributes xml, json, attr2child
    else if xml.nodeType is 3 # Text.
      json = xml.nodeValue
      return json

    # Parse Children.
    if xml.hasChildNodes()
      json = this._parseChildren xml, json, attr2child

    return json