/// This domain exposes DOM read/write operations. Each DOM Node is represented with its mirror object that has an <code>id</code>. This <code>id</code> can be used to get additional information on the Node, resolve it into the JavaScript object wrapper, etc. It is important that client receives DOM events only for the nodes that are known to the client. Backend keeps track of the nodes that were sent to the client and never sends the same node twice. It is client's responsibility to collect information about the nodes that were sent to the client.<p>Note that <code>iframe</code> owner elements will return corresponding document elements as their child nodes.</p>

import 'dart:async';
import 'package:meta/meta.dart' show required;
import '../connection.dart';
import 'page.dart' as page;
import '../runtime.dart' as runtime;
import 'dom.dart' as dom;

class DOMManager {
  final Session _client;

  DOMManager(this._client);

  final StreamController _documentUpdated = new StreamController.broadcast();

  /// Fired when <code>Document</code> has been totally updated. Node ids are no longer valid.
  Stream get onDocumentUpdated => _documentUpdated.stream;

  final StreamController<SetChildNodesResult> _setChildNodes =
      new StreamController<SetChildNodesResult>.broadcast();

  /// Fired when backend wants to provide client with the missing DOM structure. This happens upon most of the calls requesting node ids.
  Stream<SetChildNodesResult> get onSetChildNodes => _setChildNodes.stream;

  final StreamController<AttributeModifiedResult> _attributeModified =
      new StreamController<AttributeModifiedResult>.broadcast();

  /// Fired when <code>Element</code>'s attribute is modified.
  Stream<AttributeModifiedResult> get onAttributeModified =>
      _attributeModified.stream;

  final StreamController<AttributeRemovedResult> _attributeRemoved =
      new StreamController<AttributeRemovedResult>.broadcast();

  /// Fired when <code>Element</code>'s attribute is removed.
  Stream<AttributeRemovedResult> get onAttributeRemoved =>
      _attributeRemoved.stream;

  final StreamController<List<NodeId>> _inlineStyleInvalidated =
      new StreamController<List<NodeId>>.broadcast();

  /// Fired when <code>Element</code>'s inline style is modified via a CSS property modification.
  Stream<List<NodeId>> get onInlineStyleInvalidated =>
      _inlineStyleInvalidated.stream;

  final StreamController<CharacterDataModifiedResult> _characterDataModified =
      new StreamController<CharacterDataModifiedResult>.broadcast();

  /// Mirrors <code>DOMCharacterDataModified</code> event.
  Stream<CharacterDataModifiedResult> get onCharacterDataModified =>
      _characterDataModified.stream;

  final StreamController<ChildNodeCountUpdatedResult> _childNodeCountUpdated =
      new StreamController<ChildNodeCountUpdatedResult>.broadcast();

  /// Fired when <code>Container</code>'s child node count has changed.
  Stream<ChildNodeCountUpdatedResult> get onChildNodeCountUpdated =>
      _childNodeCountUpdated.stream;

  final StreamController<ChildNodeInsertedResult> _childNodeInserted =
      new StreamController<ChildNodeInsertedResult>.broadcast();

  /// Mirrors <code>DOMNodeInserted</code> event.
  Stream<ChildNodeInsertedResult> get onChildNodeInserted =>
      _childNodeInserted.stream;

  final StreamController<ChildNodeRemovedResult> _childNodeRemoved =
      new StreamController<ChildNodeRemovedResult>.broadcast();

  /// Mirrors <code>DOMNodeRemoved</code> event.
  Stream<ChildNodeRemovedResult> get onChildNodeRemoved =>
      _childNodeRemoved.stream;

  final StreamController<ShadowRootPushedResult> _shadowRootPushed =
      new StreamController<ShadowRootPushedResult>.broadcast();

  /// Called when shadow root is pushed into the element.
  Stream<ShadowRootPushedResult> get onShadowRootPushed =>
      _shadowRootPushed.stream;

  final StreamController<ShadowRootPoppedResult> _shadowRootPopped =
      new StreamController<ShadowRootPoppedResult>.broadcast();

  /// Called when shadow root is popped from the element.
  Stream<ShadowRootPoppedResult> get onShadowRootPopped =>
      _shadowRootPopped.stream;

  final StreamController<PseudoElementAddedResult> _pseudoElementAdded =
      new StreamController<PseudoElementAddedResult>.broadcast();

  /// Called when a pseudo element is added to an element.
  Stream<PseudoElementAddedResult> get onPseudoElementAdded =>
      _pseudoElementAdded.stream;

  final StreamController<PseudoElementRemovedResult> _pseudoElementRemoved =
      new StreamController<PseudoElementRemovedResult>.broadcast();

  /// Called when a pseudo element is removed from an element.
  Stream<PseudoElementRemovedResult> get onPseudoElementRemoved =>
      _pseudoElementRemoved.stream;

  final StreamController<DistributedNodesUpdatedResult>
      _distributedNodesUpdated =
      new StreamController<DistributedNodesUpdatedResult>.broadcast();

  /// Called when distrubution is changed.
  Stream<DistributedNodesUpdatedResult> get onDistributedNodesUpdated =>
      _distributedNodesUpdated.stream;

  /// Enables DOM agent for the given page.
  Future enable() async {
    await _client.send('DOM.enable');
  }

  /// Disables DOM agent for the given page.
  Future disable() async {
    await _client.send('DOM.disable');
  }

  /// Returns the root DOM node (and optionally the subtree) to the caller.
  /// [depth] The maximum depth at which children should be retrieved, defaults to 1. Use -1 for the entire subtree or provide an integer larger than 0.
  /// [pierce] Whether or not iframes and shadow roots should be traversed when returning the subtree (default is false).
  /// Return: Resulting node.
  Future<Node> getDocument({
    int depth,
    bool pierce,
  }) async {
    Map parameters = {};
    if (depth != null) {
      parameters['depth'] = depth;
    }
    if (pierce != null) {
      parameters['pierce'] = pierce;
    }
    await _client.send('DOM.getDocument', parameters);
  }

  /// Returns the root DOM node (and optionally the subtree) to the caller.
  /// [depth] The maximum depth at which children should be retrieved, defaults to 1. Use -1 for the entire subtree or provide an integer larger than 0.
  /// [pierce] Whether or not iframes and shadow roots should be traversed when returning the subtree (default is false).
  /// Return: Resulting node.
  Future<List<Node>> getFlattenedDocument({
    int depth,
    bool pierce,
  }) async {
    Map parameters = {};
    if (depth != null) {
      parameters['depth'] = depth;
    }
    if (pierce != null) {
      parameters['pierce'] = pierce;
    }
    await _client.send('DOM.getFlattenedDocument', parameters);
  }

  /// Collects class names for the node with given id and all of it's child nodes.
  /// [nodeId] Id of the node to collect class names.
  /// Return: Class name list.
  Future<List<String>> collectClassNamesFromSubtree(
    NodeId nodeId,
  ) async {
    Map parameters = {
      'nodeId': nodeId.toJson(),
    };
    await _client.send('DOM.collectClassNamesFromSubtree', parameters);
  }

  /// Requests that children of the node with given id are returned to the caller in form of <code>setChildNodes</code> events where not only immediate children are retrieved, but all children down to the specified depth.
  /// [nodeId] Id of the node to get children for.
  /// [depth] The maximum depth at which children should be retrieved, defaults to 1. Use -1 for the entire subtree or provide an integer larger than 0.
  /// [pierce] Whether or not iframes and shadow roots should be traversed when returning the sub-tree (default is false).
  Future requestChildNodes(
    NodeId nodeId, {
    int depth,
    bool pierce,
  }) async {
    Map parameters = {
      'nodeId': nodeId.toJson(),
    };
    if (depth != null) {
      parameters['depth'] = depth;
    }
    if (pierce != null) {
      parameters['pierce'] = pierce;
    }
    await _client.send('DOM.requestChildNodes', parameters);
  }

  /// Executes <code>querySelector</code> on a given node.
  /// [nodeId] Id of the node to query upon.
  /// [selector] Selector string.
  /// Return: Query selector result.
  Future<NodeId> querySelector(
    NodeId nodeId,
    String selector,
  ) async {
    Map parameters = {
      'nodeId': nodeId.toJson(),
      'selector': selector,
    };
    await _client.send('DOM.querySelector', parameters);
  }

  /// Executes <code>querySelectorAll</code> on a given node.
  /// [nodeId] Id of the node to query upon.
  /// [selector] Selector string.
  /// Return: Query selector result.
  Future<List<NodeId>> querySelectorAll(
    NodeId nodeId,
    String selector,
  ) async {
    Map parameters = {
      'nodeId': nodeId.toJson(),
      'selector': selector,
    };
    await _client.send('DOM.querySelectorAll', parameters);
  }

  /// Sets node name for a node with given id.
  /// [nodeId] Id of the node to set name for.
  /// [name] New node's name.
  /// Return: New node's id.
  Future<NodeId> setNodeName(
    NodeId nodeId,
    String name,
  ) async {
    Map parameters = {
      'nodeId': nodeId.toJson(),
      'name': name,
    };
    await _client.send('DOM.setNodeName', parameters);
  }

  /// Sets node value for a node with given id.
  /// [nodeId] Id of the node to set value for.
  /// [value] New node's value.
  Future setNodeValue(
    NodeId nodeId,
    String value,
  ) async {
    Map parameters = {
      'nodeId': nodeId.toJson(),
      'value': value,
    };
    await _client.send('DOM.setNodeValue', parameters);
  }

  /// Removes node with given id.
  /// [nodeId] Id of the node to remove.
  Future removeNode(
    NodeId nodeId,
  ) async {
    Map parameters = {
      'nodeId': nodeId.toJson(),
    };
    await _client.send('DOM.removeNode', parameters);
  }

  /// Sets attribute for an element with given id.
  /// [nodeId] Id of the element to set attribute for.
  /// [name] Attribute name.
  /// [value] Attribute value.
  Future setAttributeValue(
    NodeId nodeId,
    String name,
    String value,
  ) async {
    Map parameters = {
      'nodeId': nodeId.toJson(),
      'name': name,
      'value': value,
    };
    await _client.send('DOM.setAttributeValue', parameters);
  }

  /// Sets attributes on element with given id. This method is useful when user edits some existing attribute value and types in several attribute name/value pairs.
  /// [nodeId] Id of the element to set attributes for.
  /// [text] Text with a number of attributes. Will parse this text using HTML parser.
  /// [name] Attribute name to replace with new attributes derived from text in case text parsed successfully.
  Future setAttributesAsText(
    NodeId nodeId,
    String text, {
    String name,
  }) async {
    Map parameters = {
      'nodeId': nodeId.toJson(),
      'text': text,
    };
    if (name != null) {
      parameters['name'] = name;
    }
    await _client.send('DOM.setAttributesAsText', parameters);
  }

  /// Removes attribute with given name from an element with given id.
  /// [nodeId] Id of the element to remove attribute from.
  /// [name] Name of the attribute to remove.
  Future removeAttribute(
    NodeId nodeId,
    String name,
  ) async {
    Map parameters = {
      'nodeId': nodeId.toJson(),
      'name': name,
    };
    await _client.send('DOM.removeAttribute', parameters);
  }

  /// Returns node's HTML markup.
  /// [nodeId] Id of the node to get markup for.
  /// Return: Outer HTML markup.
  Future<String> getOuterHTML(
    NodeId nodeId,
  ) async {
    Map parameters = {
      'nodeId': nodeId.toJson(),
    };
    await _client.send('DOM.getOuterHTML', parameters);
  }

  /// Sets node HTML markup, returns new node id.
  /// [nodeId] Id of the node to set markup for.
  /// [outerHTML] Outer HTML markup to set.
  Future setOuterHTML(
    NodeId nodeId,
    String outerHTML,
  ) async {
    Map parameters = {
      'nodeId': nodeId.toJson(),
      'outerHTML': outerHTML,
    };
    await _client.send('DOM.setOuterHTML', parameters);
  }

  /// Searches for a given string in the DOM tree. Use <code>getSearchResults</code> to access search results or <code>cancelSearch</code> to end this search session.
  /// [query] Plain text or query selector or XPath search query.
  /// [includeUserAgentShadowDOM] True to search in user agent shadow DOM.
  Future<PerformSearchResult> performSearch(
    String query, {
    bool includeUserAgentShadowDOM,
  }) async {
    Map parameters = {
      'query': query,
    };
    if (includeUserAgentShadowDOM != null) {
      parameters['includeUserAgentShadowDOM'] = includeUserAgentShadowDOM;
    }
    await _client.send('DOM.performSearch', parameters);
  }

  /// Returns search results from given <code>fromIndex</code> to given <code>toIndex</code> from the sarch with the given identifier.
  /// [searchId] Unique search session identifier.
  /// [fromIndex] Start index of the search result to be returned.
  /// [toIndex] End index of the search result to be returned.
  /// Return: Ids of the search result nodes.
  Future<List<NodeId>> getSearchResults(
    String searchId,
    int fromIndex,
    int toIndex,
  ) async {
    Map parameters = {
      'searchId': searchId,
      'fromIndex': fromIndex,
      'toIndex': toIndex,
    };
    await _client.send('DOM.getSearchResults', parameters);
  }

  /// Discards search results from the session with the given id. <code>getSearchResults</code> should no longer be called for that search.
  /// [searchId] Unique search session identifier.
  Future discardSearchResults(
    String searchId,
  ) async {
    Map parameters = {
      'searchId': searchId,
    };
    await _client.send('DOM.discardSearchResults', parameters);
  }

  /// Requests that the node is sent to the caller given the JavaScript node object reference. All nodes that form the path from the node to the root are also sent to the client as a series of <code>setChildNodes</code> notifications.
  /// [objectId] JavaScript object id to convert into node.
  /// Return: Node id for given object.
  Future<NodeId> requestNode(
    runtime.RemoteObjectId objectId,
  ) async {
    Map parameters = {
      'objectId': objectId.toJson(),
    };
    await _client.send('DOM.requestNode', parameters);
  }

  /// Highlights given rectangle.
  Future highlightRect() async {
    await _client.send('DOM.highlightRect');
  }

  /// Highlights DOM node.
  Future highlightNode() async {
    await _client.send('DOM.highlightNode');
  }

  /// Hides any highlight.
  Future hideHighlight() async {
    await _client.send('DOM.hideHighlight');
  }

  /// Requests that the node is sent to the caller given its path. // FIXME, use XPath
  /// [path] Path to node in the proprietary format.
  /// Return: Id of the node for given path.
  Future<NodeId> pushNodeByPathToFrontend(
    String path,
  ) async {
    Map parameters = {
      'path': path,
    };
    await _client.send('DOM.pushNodeByPathToFrontend', parameters);
  }

  /// Requests that a batch of nodes is sent to the caller given their backend node ids.
  /// [backendNodeIds] The array of backend node ids.
  /// Return: The array of ids of pushed nodes that correspond to the backend ids specified in backendNodeIds.
  Future<List<NodeId>> pushNodesByBackendIdsToFrontend(
    List<BackendNodeId> backendNodeIds,
  ) async {
    Map parameters = {
      'backendNodeIds': backendNodeIds.map((e) => e.toJson()).toList(),
    };
    await _client.send('DOM.pushNodesByBackendIdsToFrontend', parameters);
  }

  /// Enables console to refer to the node with given id via $x (see Command Line API for more details $x functions).
  /// [nodeId] DOM node id to be accessible by means of $x command line API.
  Future setInspectedNode(
    NodeId nodeId,
  ) async {
    Map parameters = {
      'nodeId': nodeId.toJson(),
    };
    await _client.send('DOM.setInspectedNode', parameters);
  }

  /// Resolves the JavaScript node object for a given NodeId or BackendNodeId.
  /// [nodeId] Id of the node to resolve.
  /// [backendNodeId] Backend identifier of the node to resolve.
  /// [objectGroup] Symbolic group name that can be used to release multiple objects.
  /// Return: JavaScript object wrapper for given node.
  Future<runtime.RemoteObject> resolveNode({
    NodeId nodeId,
    dom.BackendNodeId backendNodeId,
    String objectGroup,
  }) async {
    Map parameters = {};
    if (nodeId != null) {
      parameters['nodeId'] = nodeId.toJson();
    }
    if (backendNodeId != null) {
      parameters['backendNodeId'] = backendNodeId.toJson();
    }
    if (objectGroup != null) {
      parameters['objectGroup'] = objectGroup;
    }
    await _client.send('DOM.resolveNode', parameters);
  }

  /// Returns attributes for the specified node.
  /// [nodeId] Id of the node to retrieve attibutes for.
  /// Return: An interleaved array of node attribute names and values.
  Future<List<String>> getAttributes(
    NodeId nodeId,
  ) async {
    Map parameters = {
      'nodeId': nodeId.toJson(),
    };
    await _client.send('DOM.getAttributes', parameters);
  }

  /// Creates a deep copy of the specified node and places it into the target container before the given anchor.
  /// [nodeId] Id of the node to copy.
  /// [targetNodeId] Id of the element to drop the copy into.
  /// [insertBeforeNodeId] Drop the copy before this node (if absent, the copy becomes the last child of <code>targetNodeId</code>).
  /// Return: Id of the node clone.
  Future<NodeId> copyTo(
    NodeId nodeId,
    NodeId targetNodeId, {
    NodeId insertBeforeNodeId,
  }) async {
    Map parameters = {
      'nodeId': nodeId.toJson(),
      'targetNodeId': targetNodeId.toJson(),
    };
    if (insertBeforeNodeId != null) {
      parameters['insertBeforeNodeId'] = insertBeforeNodeId.toJson();
    }
    await _client.send('DOM.copyTo', parameters);
  }

  /// Moves node into the new container, places it before the given anchor.
  /// [nodeId] Id of the node to move.
  /// [targetNodeId] Id of the element to drop the moved node into.
  /// [insertBeforeNodeId] Drop node before this one (if absent, the moved node becomes the last child of <code>targetNodeId</code>).
  /// Return: New id of the moved node.
  Future<NodeId> moveTo(
    NodeId nodeId,
    NodeId targetNodeId, {
    NodeId insertBeforeNodeId,
  }) async {
    Map parameters = {
      'nodeId': nodeId.toJson(),
      'targetNodeId': targetNodeId.toJson(),
    };
    if (insertBeforeNodeId != null) {
      parameters['insertBeforeNodeId'] = insertBeforeNodeId.toJson();
    }
    await _client.send('DOM.moveTo', parameters);
  }

  /// Undoes the last performed action.
  Future undo() async {
    await _client.send('DOM.undo');
  }

  /// Re-does the last undone action.
  Future redo() async {
    await _client.send('DOM.redo');
  }

  /// Marks last undoable state.
  Future markUndoableState() async {
    await _client.send('DOM.markUndoableState');
  }

  /// Focuses the given element.
  /// [nodeId] Identifier of the node.
  /// [backendNodeId] Identifier of the backend node.
  /// [objectId] JavaScript object id of the node wrapper.
  Future focus({
    NodeId nodeId,
    BackendNodeId backendNodeId,
    runtime.RemoteObjectId objectId,
  }) async {
    Map parameters = {};
    if (nodeId != null) {
      parameters['nodeId'] = nodeId.toJson();
    }
    if (backendNodeId != null) {
      parameters['backendNodeId'] = backendNodeId.toJson();
    }
    if (objectId != null) {
      parameters['objectId'] = objectId.toJson();
    }
    await _client.send('DOM.focus', parameters);
  }

  /// Sets files for the given file input element.
  /// [files] Array of file paths to set.
  /// [nodeId] Identifier of the node.
  /// [backendNodeId] Identifier of the backend node.
  /// [objectId] JavaScript object id of the node wrapper.
  Future setFileInputFiles(
    List<String> files, {
    NodeId nodeId,
    BackendNodeId backendNodeId,
    runtime.RemoteObjectId objectId,
  }) async {
    Map parameters = {
      'files': files.map((e) => e).toList(),
    };
    if (nodeId != null) {
      parameters['nodeId'] = nodeId.toJson();
    }
    if (backendNodeId != null) {
      parameters['backendNodeId'] = backendNodeId.toJson();
    }
    if (objectId != null) {
      parameters['objectId'] = objectId.toJson();
    }
    await _client.send('DOM.setFileInputFiles', parameters);
  }

  /// Returns boxes for the currently selected nodes.
  /// [nodeId] Identifier of the node.
  /// [backendNodeId] Identifier of the backend node.
  /// [objectId] JavaScript object id of the node wrapper.
  /// Return: Box model for the node.
  Future<BoxModel> getBoxModel({
    NodeId nodeId,
    BackendNodeId backendNodeId,
    runtime.RemoteObjectId objectId,
  }) async {
    Map parameters = {};
    if (nodeId != null) {
      parameters['nodeId'] = nodeId.toJson();
    }
    if (backendNodeId != null) {
      parameters['backendNodeId'] = backendNodeId.toJson();
    }
    if (objectId != null) {
      parameters['objectId'] = objectId.toJson();
    }
    await _client.send('DOM.getBoxModel', parameters);
  }

  /// Returns node id at given location.
  /// [x] X coordinate.
  /// [y] Y coordinate.
  /// [includeUserAgentShadowDOM] False to skip to the nearest non-UA shadow root ancestor (default: false).
  /// Return: Id of the node at given coordinates.
  Future<NodeId> getNodeForLocation(
    int x,
    int y, {
    bool includeUserAgentShadowDOM,
  }) async {
    Map parameters = {
      'x': x,
      'y': y,
    };
    if (includeUserAgentShadowDOM != null) {
      parameters['includeUserAgentShadowDOM'] = includeUserAgentShadowDOM;
    }
    await _client.send('DOM.getNodeForLocation', parameters);
  }

  /// Returns the id of the nearest ancestor that is a relayout boundary.
  /// [nodeId] Id of the node.
  /// Return: Relayout boundary node id for the given node.
  Future<NodeId> getRelayoutBoundary(
    NodeId nodeId,
  ) async {
    Map parameters = {
      'nodeId': nodeId.toJson(),
    };
    await _client.send('DOM.getRelayoutBoundary', parameters);
  }
}

class SetChildNodesResult {
  /// Parent node id to populate with children.
  final NodeId parentId;

  /// Child nodes array.
  final List<Node> nodes;

  SetChildNodesResult({
    @required this.parentId,
    @required this.nodes,
  });

  factory SetChildNodesResult.fromJson(Map json) {
    return new SetChildNodesResult(
      parentId: new NodeId.fromJson(json['parentId']),
      nodes: (json['nodes'] as List).map((e) => new Node.fromJson(e)).toList(),
    );
  }
}

class AttributeModifiedResult {
  /// Id of the node that has changed.
  final NodeId nodeId;

  /// Attribute name.
  final String name;

  /// Attribute value.
  final String value;

  AttributeModifiedResult({
    @required this.nodeId,
    @required this.name,
    @required this.value,
  });

  factory AttributeModifiedResult.fromJson(Map json) {
    return new AttributeModifiedResult(
      nodeId: new NodeId.fromJson(json['nodeId']),
      name: json['name'],
      value: json['value'],
    );
  }
}

class AttributeRemovedResult {
  /// Id of the node that has changed.
  final NodeId nodeId;

  /// A ttribute name.
  final String name;

  AttributeRemovedResult({
    @required this.nodeId,
    @required this.name,
  });

  factory AttributeRemovedResult.fromJson(Map json) {
    return new AttributeRemovedResult(
      nodeId: new NodeId.fromJson(json['nodeId']),
      name: json['name'],
    );
  }
}

class CharacterDataModifiedResult {
  /// Id of the node that has changed.
  final NodeId nodeId;

  /// New text value.
  final String characterData;

  CharacterDataModifiedResult({
    @required this.nodeId,
    @required this.characterData,
  });

  factory CharacterDataModifiedResult.fromJson(Map json) {
    return new CharacterDataModifiedResult(
      nodeId: new NodeId.fromJson(json['nodeId']),
      characterData: json['characterData'],
    );
  }
}

class ChildNodeCountUpdatedResult {
  /// Id of the node that has changed.
  final NodeId nodeId;

  /// New node count.
  final int childNodeCount;

  ChildNodeCountUpdatedResult({
    @required this.nodeId,
    @required this.childNodeCount,
  });

  factory ChildNodeCountUpdatedResult.fromJson(Map json) {
    return new ChildNodeCountUpdatedResult(
      nodeId: new NodeId.fromJson(json['nodeId']),
      childNodeCount: json['childNodeCount'],
    );
  }
}

class ChildNodeInsertedResult {
  /// Id of the node that has changed.
  final NodeId parentNodeId;

  /// If of the previous siblint.
  final NodeId previousNodeId;

  /// Inserted node data.
  final Node node;

  ChildNodeInsertedResult({
    @required this.parentNodeId,
    @required this.previousNodeId,
    @required this.node,
  });

  factory ChildNodeInsertedResult.fromJson(Map json) {
    return new ChildNodeInsertedResult(
      parentNodeId: new NodeId.fromJson(json['parentNodeId']),
      previousNodeId: new NodeId.fromJson(json['previousNodeId']),
      node: new Node.fromJson(json['node']),
    );
  }
}

class ChildNodeRemovedResult {
  /// Parent id.
  final NodeId parentNodeId;

  /// Id of the node that has been removed.
  final NodeId nodeId;

  ChildNodeRemovedResult({
    @required this.parentNodeId,
    @required this.nodeId,
  });

  factory ChildNodeRemovedResult.fromJson(Map json) {
    return new ChildNodeRemovedResult(
      parentNodeId: new NodeId.fromJson(json['parentNodeId']),
      nodeId: new NodeId.fromJson(json['nodeId']),
    );
  }
}

class ShadowRootPushedResult {
  /// Host element id.
  final NodeId hostId;

  /// Shadow root.
  final Node root;

  ShadowRootPushedResult({
    @required this.hostId,
    @required this.root,
  });

  factory ShadowRootPushedResult.fromJson(Map json) {
    return new ShadowRootPushedResult(
      hostId: new NodeId.fromJson(json['hostId']),
      root: new Node.fromJson(json['root']),
    );
  }
}

class ShadowRootPoppedResult {
  /// Host element id.
  final NodeId hostId;

  /// Shadow root id.
  final NodeId rootId;

  ShadowRootPoppedResult({
    @required this.hostId,
    @required this.rootId,
  });

  factory ShadowRootPoppedResult.fromJson(Map json) {
    return new ShadowRootPoppedResult(
      hostId: new NodeId.fromJson(json['hostId']),
      rootId: new NodeId.fromJson(json['rootId']),
    );
  }
}

class PseudoElementAddedResult {
  /// Pseudo element's parent element id.
  final NodeId parentId;

  /// The added pseudo element.
  final Node pseudoElement;

  PseudoElementAddedResult({
    @required this.parentId,
    @required this.pseudoElement,
  });

  factory PseudoElementAddedResult.fromJson(Map json) {
    return new PseudoElementAddedResult(
      parentId: new NodeId.fromJson(json['parentId']),
      pseudoElement: new Node.fromJson(json['pseudoElement']),
    );
  }
}

class PseudoElementRemovedResult {
  /// Pseudo element's parent element id.
  final NodeId parentId;

  /// The removed pseudo element id.
  final NodeId pseudoElementId;

  PseudoElementRemovedResult({
    @required this.parentId,
    @required this.pseudoElementId,
  });

  factory PseudoElementRemovedResult.fromJson(Map json) {
    return new PseudoElementRemovedResult(
      parentId: new NodeId.fromJson(json['parentId']),
      pseudoElementId: new NodeId.fromJson(json['pseudoElementId']),
    );
  }
}

class DistributedNodesUpdatedResult {
  /// Insertion point where distrubuted nodes were updated.
  final NodeId insertionPointId;

  /// Distributed nodes for given insertion point.
  final List<BackendNode> distributedNodes;

  DistributedNodesUpdatedResult({
    @required this.insertionPointId,
    @required this.distributedNodes,
  });

  factory DistributedNodesUpdatedResult.fromJson(Map json) {
    return new DistributedNodesUpdatedResult(
      insertionPointId: new NodeId.fromJson(json['insertionPointId']),
      distributedNodes: (json['distributedNodes'] as List)
          .map((e) => new BackendNode.fromJson(e))
          .toList(),
    );
  }
}

class PerformSearchResult {
  /// Unique search session identifier.
  final String searchId;

  /// Number of search results.
  final int resultCount;

  PerformSearchResult({
    @required this.searchId,
    @required this.resultCount,
  });

  factory PerformSearchResult.fromJson(Map json) {
    return new PerformSearchResult(
      searchId: json['searchId'],
      resultCount: json['resultCount'],
    );
  }
}

/// Unique DOM node identifier.
class NodeId {
  final int value;

  NodeId(this.value);

  factory NodeId.fromJson(int value) => new NodeId(value);

  int toJson() => value;
}

/// Unique DOM node identifier used to reference a node that may not have been pushed to the front-end.
class BackendNodeId {
  final int value;

  BackendNodeId(this.value);

  factory BackendNodeId.fromJson(int value) => new BackendNodeId(value);

  int toJson() => value;
}

/// Backend node with a friendly name.
class BackendNode {
  /// <code>Node</code>'s nodeType.
  final int nodeType;

  /// <code>Node</code>'s nodeName.
  final String nodeName;

  final BackendNodeId backendNodeId;

  BackendNode({
    @required this.nodeType,
    @required this.nodeName,
    @required this.backendNodeId,
  });

  factory BackendNode.fromJson(Map json) {
    return new BackendNode(
      nodeType: json['nodeType'],
      nodeName: json['nodeName'],
      backendNodeId: new BackendNodeId.fromJson(json['backendNodeId']),
    );
  }

  Map toJson() {
    Map json = {
      'nodeType': nodeType,
      'nodeName': nodeName,
      'backendNodeId': backendNodeId.toJson(),
    };
    return json;
  }
}

/// Pseudo element type.
class PseudoType {
  static const PseudoType firstLine = const PseudoType._('first-line');
  static const PseudoType firstLetter = const PseudoType._('first-letter');
  static const PseudoType before = const PseudoType._('before');
  static const PseudoType after = const PseudoType._('after');
  static const PseudoType backdrop = const PseudoType._('backdrop');
  static const PseudoType selection = const PseudoType._('selection');
  static const PseudoType firstLineInherited =
      const PseudoType._('first-line-inherited');
  static const PseudoType scrollbar = const PseudoType._('scrollbar');
  static const PseudoType scrollbarThumb =
      const PseudoType._('scrollbar-thumb');
  static const PseudoType scrollbarButton =
      const PseudoType._('scrollbar-button');
  static const PseudoType scrollbarTrack =
      const PseudoType._('scrollbar-track');
  static const PseudoType scrollbarTrackPiece =
      const PseudoType._('scrollbar-track-piece');
  static const PseudoType scrollbarCorner =
      const PseudoType._('scrollbar-corner');
  static const PseudoType resizer = const PseudoType._('resizer');
  static const PseudoType inputListButton =
      const PseudoType._('input-list-button');
  static const values = const {
    'first-line': firstLine,
    'first-letter': firstLetter,
    'before': before,
    'after': after,
    'backdrop': backdrop,
    'selection': selection,
    'first-line-inherited': firstLineInherited,
    'scrollbar': scrollbar,
    'scrollbar-thumb': scrollbarThumb,
    'scrollbar-button': scrollbarButton,
    'scrollbar-track': scrollbarTrack,
    'scrollbar-track-piece': scrollbarTrackPiece,
    'scrollbar-corner': scrollbarCorner,
    'resizer': resizer,
    'input-list-button': inputListButton,
  };

  final String value;

  const PseudoType._(this.value);

  factory PseudoType.fromJson(String value) => values[value];

  String toJson() => value;
}

/// Shadow root type.
class ShadowRootType {
  static const ShadowRootType userAgent = const ShadowRootType._('user-agent');
  static const ShadowRootType open = const ShadowRootType._('open');
  static const ShadowRootType closed = const ShadowRootType._('closed');
  static const values = const {
    'user-agent': userAgent,
    'open': open,
    'closed': closed,
  };

  final String value;

  const ShadowRootType._(this.value);

  factory ShadowRootType.fromJson(String value) => values[value];

  String toJson() => value;
}

/// DOM interaction is implemented in terms of mirror objects that represent the actual DOM nodes. DOMNode is a base node mirror type.
class Node {
  /// Node identifier that is passed into the rest of the DOM messages as the <code>nodeId</code>. Backend will only push node with given <code>id</code> once. It is aware of all requested nodes and will only fire DOM events for nodes known to the client.
  final NodeId nodeId;

  /// The id of the parent node if any.
  final NodeId parentId;

  /// The BackendNodeId for this node.
  final BackendNodeId backendNodeId;

  /// <code>Node</code>'s nodeType.
  final int nodeType;

  /// <code>Node</code>'s nodeName.
  final String nodeName;

  /// <code>Node</code>'s localName.
  final String localName;

  /// <code>Node</code>'s nodeValue.
  final String nodeValue;

  /// Child count for <code>Container</code> nodes.
  final int childNodeCount;

  /// Child nodes of this node when requested with children.
  final List<Node> children;

  /// Attributes of the <code>Element</code> node in the form of flat array <code>[name1, value1, name2, value2]</code>.
  final List<String> attributes;

  /// Document URL that <code>Document</code> or <code>FrameOwner</code> node points to.
  final String documentURL;

  /// Base URL that <code>Document</code> or <code>FrameOwner</code> node uses for URL completion.
  final String baseURL;

  /// <code>DocumentType</code>'s publicId.
  final String publicId;

  /// <code>DocumentType</code>'s systemId.
  final String systemId;

  /// <code>DocumentType</code>'s internalSubset.
  final String internalSubset;

  /// <code>Document</code>'s XML version in case of XML documents.
  final String xmlVersion;

  /// <code>Attr</code>'s name.
  final String name;

  /// <code>Attr</code>'s value.
  final String value;

  /// Pseudo element type for this node.
  final PseudoType pseudoType;

  /// Shadow root type.
  final ShadowRootType shadowRootType;

  /// Frame ID for frame owner elements.
  final page.FrameId frameId;

  /// Content document for frame owner elements.
  final Node contentDocument;

  /// Shadow root list for given element host.
  final List<Node> shadowRoots;

  /// Content document fragment for template elements.
  final Node templateContent;

  /// Pseudo elements associated with this node.
  final List<Node> pseudoElements;

  /// Import document for the HTMLImport links.
  final Node importedDocument;

  /// Distributed nodes for given insertion point.
  final List<BackendNode> distributedNodes;

  /// Whether the node is SVG.
  final bool isSVG;

  Node({
    @required this.nodeId,
    this.parentId,
    @required this.backendNodeId,
    @required this.nodeType,
    @required this.nodeName,
    @required this.localName,
    @required this.nodeValue,
    this.childNodeCount,
    this.children,
    this.attributes,
    this.documentURL,
    this.baseURL,
    this.publicId,
    this.systemId,
    this.internalSubset,
    this.xmlVersion,
    this.name,
    this.value,
    this.pseudoType,
    this.shadowRootType,
    this.frameId,
    this.contentDocument,
    this.shadowRoots,
    this.templateContent,
    this.pseudoElements,
    this.importedDocument,
    this.distributedNodes,
    this.isSVG,
  });

  factory Node.fromJson(Map json) {
    return new Node(
      nodeId: new NodeId.fromJson(json['nodeId']),
      parentId: json.containsKey('parentId')
          ? new NodeId.fromJson(json['parentId'])
          : null,
      backendNodeId: new BackendNodeId.fromJson(json['backendNodeId']),
      nodeType: json['nodeType'],
      nodeName: json['nodeName'],
      localName: json['localName'],
      nodeValue: json['nodeValue'],
      childNodeCount:
          json.containsKey('childNodeCount') ? json['childNodeCount'] : null,
      children: json.containsKey('children')
          ? (json['children'] as List).map((e) => new Node.fromJson(e)).toList()
          : null,
      attributes: json.containsKey('attributes')
          ? (json['attributes'] as List).map((e) => e as String).toList()
          : null,
      documentURL: json.containsKey('documentURL') ? json['documentURL'] : null,
      baseURL: json.containsKey('baseURL') ? json['baseURL'] : null,
      publicId: json.containsKey('publicId') ? json['publicId'] : null,
      systemId: json.containsKey('systemId') ? json['systemId'] : null,
      internalSubset:
          json.containsKey('internalSubset') ? json['internalSubset'] : null,
      xmlVersion: json.containsKey('xmlVersion') ? json['xmlVersion'] : null,
      name: json.containsKey('name') ? json['name'] : null,
      value: json.containsKey('value') ? json['value'] : null,
      pseudoType: json.containsKey('pseudoType')
          ? new PseudoType.fromJson(json['pseudoType'])
          : null,
      shadowRootType: json.containsKey('shadowRootType')
          ? new ShadowRootType.fromJson(json['shadowRootType'])
          : null,
      frameId: json.containsKey('frameId')
          ? new page.FrameId.fromJson(json['frameId'])
          : null,
      contentDocument: json.containsKey('contentDocument')
          ? new Node.fromJson(json['contentDocument'])
          : null,
      shadowRoots: json.containsKey('shadowRoots')
          ? (json['shadowRoots'] as List)
              .map((e) => new Node.fromJson(e))
              .toList()
          : null,
      templateContent: json.containsKey('templateContent')
          ? new Node.fromJson(json['templateContent'])
          : null,
      pseudoElements: json.containsKey('pseudoElements')
          ? (json['pseudoElements'] as List)
              .map((e) => new Node.fromJson(e))
              .toList()
          : null,
      importedDocument: json.containsKey('importedDocument')
          ? new Node.fromJson(json['importedDocument'])
          : null,
      distributedNodes: json.containsKey('distributedNodes')
          ? (json['distributedNodes'] as List)
              .map((e) => new BackendNode.fromJson(e))
              .toList()
          : null,
      isSVG: json.containsKey('isSVG') ? json['isSVG'] : null,
    );
  }

  Map toJson() {
    Map json = {
      'nodeId': nodeId.toJson(),
      'backendNodeId': backendNodeId.toJson(),
      'nodeType': nodeType,
      'nodeName': nodeName,
      'localName': localName,
      'nodeValue': nodeValue,
    };
    if (parentId != null) {
      json['parentId'] = parentId.toJson();
    }
    if (childNodeCount != null) {
      json['childNodeCount'] = childNodeCount;
    }
    if (children != null) {
      json['children'] = children.map((e) => e.toJson()).toList();
    }
    if (attributes != null) {
      json['attributes'] = attributes.map((e) => e).toList();
    }
    if (documentURL != null) {
      json['documentURL'] = documentURL;
    }
    if (baseURL != null) {
      json['baseURL'] = baseURL;
    }
    if (publicId != null) {
      json['publicId'] = publicId;
    }
    if (systemId != null) {
      json['systemId'] = systemId;
    }
    if (internalSubset != null) {
      json['internalSubset'] = internalSubset;
    }
    if (xmlVersion != null) {
      json['xmlVersion'] = xmlVersion;
    }
    if (name != null) {
      json['name'] = name;
    }
    if (value != null) {
      json['value'] = value;
    }
    if (pseudoType != null) {
      json['pseudoType'] = pseudoType.toJson();
    }
    if (shadowRootType != null) {
      json['shadowRootType'] = shadowRootType.toJson();
    }
    if (frameId != null) {
      json['frameId'] = frameId.toJson();
    }
    if (contentDocument != null) {
      json['contentDocument'] = contentDocument.toJson();
    }
    if (shadowRoots != null) {
      json['shadowRoots'] = shadowRoots.map((e) => e.toJson()).toList();
    }
    if (templateContent != null) {
      json['templateContent'] = templateContent.toJson();
    }
    if (pseudoElements != null) {
      json['pseudoElements'] = pseudoElements.map((e) => e.toJson()).toList();
    }
    if (importedDocument != null) {
      json['importedDocument'] = importedDocument.toJson();
    }
    if (distributedNodes != null) {
      json['distributedNodes'] =
          distributedNodes.map((e) => e.toJson()).toList();
    }
    if (isSVG != null) {
      json['isSVG'] = isSVG;
    }
    return json;
  }
}

/// A structure holding an RGBA color.
class RGBA {
  /// The red component, in the [0-255] range.
  final int r;

  /// The green component, in the [0-255] range.
  final int g;

  /// The blue component, in the [0-255] range.
  final int b;

  /// The alpha component, in the [0-1] range (default: 1).
  final num a;

  RGBA({
    @required this.r,
    @required this.g,
    @required this.b,
    this.a,
  });

  factory RGBA.fromJson(Map json) {
    return new RGBA(
      r: json['r'],
      g: json['g'],
      b: json['b'],
      a: json.containsKey('a') ? json['a'] : null,
    );
  }

  Map toJson() {
    Map json = {
      'r': r,
      'g': g,
      'b': b,
    };
    if (a != null) {
      json['a'] = a;
    }
    return json;
  }
}

/// An array of quad vertices, x immediately followed by y for each point, points clock-wise.
class Quad {
  final List<num> value;

  Quad(this.value);

  factory Quad.fromJson(List<num> value) => new Quad(value);

  List<num> toJson() => value;
}

/// Box model.
class BoxModel {
  /// Content box
  final Quad content;

  /// Padding box
  final Quad padding;

  /// Border box
  final Quad border;

  /// Margin box
  final Quad margin;

  /// Node width
  final int width;

  /// Node height
  final int height;

  /// Shape outside coordinates
  final ShapeOutsideInfo shapeOutside;

  BoxModel({
    @required this.content,
    @required this.padding,
    @required this.border,
    @required this.margin,
    @required this.width,
    @required this.height,
    this.shapeOutside,
  });

  factory BoxModel.fromJson(Map json) {
    return new BoxModel(
      content: new Quad.fromJson(json['content']),
      padding: new Quad.fromJson(json['padding']),
      border: new Quad.fromJson(json['border']),
      margin: new Quad.fromJson(json['margin']),
      width: json['width'],
      height: json['height'],
      shapeOutside: json.containsKey('shapeOutside')
          ? new ShapeOutsideInfo.fromJson(json['shapeOutside'])
          : null,
    );
  }

  Map toJson() {
    Map json = {
      'content': content.toJson(),
      'padding': padding.toJson(),
      'border': border.toJson(),
      'margin': margin.toJson(),
      'width': width,
      'height': height,
    };
    if (shapeOutside != null) {
      json['shapeOutside'] = shapeOutside.toJson();
    }
    return json;
  }
}

/// CSS Shape Outside details.
class ShapeOutsideInfo {
  /// Shape bounds
  final Quad bounds;

  /// Shape coordinate details
  final List<dynamic> shape;

  /// Margin shape bounds
  final List<dynamic> marginShape;

  ShapeOutsideInfo({
    @required this.bounds,
    @required this.shape,
    @required this.marginShape,
  });

  factory ShapeOutsideInfo.fromJson(Map json) {
    return new ShapeOutsideInfo(
      bounds: new Quad.fromJson(json['bounds']),
      shape: (json['shape'] as List).map((e) => e as dynamic).toList(),
      marginShape:
          (json['marginShape'] as List).map((e) => e as dynamic).toList(),
    );
  }

  Map toJson() {
    Map json = {
      'bounds': bounds.toJson(),
      'shape': shape.map((e) => e.toJson()).toList(),
      'marginShape': marginShape.map((e) => e.toJson()).toList(),
    };
    return json;
  }
}

/// Rectangle.
class Rect {
  /// X coordinate
  final num x;

  /// Y coordinate
  final num y;

  /// Rectangle width
  final num width;

  /// Rectangle height
  final num height;

  Rect({
    @required this.x,
    @required this.y,
    @required this.width,
    @required this.height,
  });

  factory Rect.fromJson(Map json) {
    return new Rect(
      x: json['x'],
      y: json['y'],
      width: json['width'],
      height: json['height'],
    );
  }

  Map toJson() {
    Map json = {
      'x': x,
      'y': y,
      'width': width,
      'height': height,
    };
    return json;
  }
}
