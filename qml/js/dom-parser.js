.pragma library

// NodeAttribute.js
function NodeAttribute(name, value) {
    this.name = name;
    this.value = value;
}


// Node.js (lol)
var NodeType = {1: 'element', 'element': 1, 3: 'text', 'text': 3};
// NodeType[1] = "element";
// NodeType["element"] = 1
// NodeType[3] = "text";
// NodeType["text"] = 3

function Node(nodeType, namespace, selfCloseTag, text, nodeName, childNodes, parentNode, attributes) {
    this.namespace = namespace || null;
    this.nodeType = nodeType;
    this.isSelfCloseTag = Boolean(selfCloseTag);
    this.text = text || null;
    this.nodeName = nodeType === NodeType.element ? nodeName : '#text';
    this.childNodes = childNodes || [];
    this.parentNode = parentNode;
    this.attributes = attributes || [];
}

Node.prototype.firstChild = function() {
    return this.childNodes[0] || null;
}
Node.prototype.lastChild = function() {
    return this.childNodes[this.childNodes.length - 1] || null;
}
Node.prototype.innerHTML = function() {
    return this.childNodes.reduce(function (html, node) { return html + (node.nodeType === NodeType.text ? node.text : node.outerHTML()) }, '');
}
Node.prototype.outerHTML = function() {
    if (this.nodeType === NodeType.text) {
        return this.textContent();
    }
    var attributesString = stringifyAttributes(this.attributes);
    var openTag = '<' + this.nodeName + (attributesString.length ? ' ' : '') + attributesString + (this.isSelfCloseTag ? '/' : '') + '>';
    if (this.isSelfCloseTag) {
        return openTag;
    }
    var childs = this.childNodes.map(function (child) { return child.outerHTML() }).join('');
    var closeTag = '</' + this.nodeName + '>';
    return [openTag, childs, closeTag].join('');
}
Node.prototype.textContent = function() {
    if (this.nodeType === NodeType.text) {
        return this.text;
    }
    return this.childNodes
        .map(function (node) { return node.textContent() })
        .join('')
        .replace(/\x20+/g, ' ');
}
Node.prototype.getAttribute = function(name) {
    for (var i=0; i < this.attributes.length; i++)
        if (this.attributes[i].name === name)
            return this.attributes[i].value
    return null;
}
Node.prototype.getElementsByTagName = function(tagName) {
    return searchElements(this, function (elem) { return elem.nodeName.toUpperCase() === tagName.toUpperCase() });
}
Node.prototype.getElementsByClassName = function(className) {
    var expr = new RegExp('^(.*?\\s)?' + className + '(\\s.*?)?$');
    return searchElements(this, function (node) { return Boolean(node.attributes.length && expr.test(node.getAttribute('class') || '')) });
}
Node.prototype.getElementsByName = function(name) {
    return searchElements(this, function (node) { return Boolean(node.attributes.length && node.getAttribute('name') === name) });
}
Node.prototype.getElementById = function(id) {
    return searchElement(this, function (node) { return Boolean(node.attributes.length && node.getAttribute('id') === id) });
}

Node.ELEMENT_NODE = NodeType.element;
Node.TEXT_NODE = NodeType.text;
// private
function searchElements(root, conditionFn) {
    if (root.nodeType === NodeType.text) {
        return [];
    }
    return root.childNodes.reduce(function (accumulator, childNode) {
        if (childNode.nodeType !== NodeType.text && conditionFn(childNode)) {
            return accumulator.concat(childNode, searchElements(childNode, conditionFn));
        }
        return accumulator.concat(searchElements(childNode, conditionFn));
    }, []);
}
function searchElement(root, conditionFn) {
    for (var i = 0, l = root.childNodes.length; i < l; i++) {
        var childNode = root.childNodes[i];
        if (conditionFn(childNode)) {
            return childNode;
        }
        var node = searchElement(childNode, conditionFn);
        if (node) {
            return node;
        }
    }
    return null;
}
function stringifyAttributes(attributes) {
    return attributes.map(function (elem) { return elem.name + (elem.value ? '="' + elem.value + '"' : '') }).join(' ');
}




// Dom.js
var tagRegExp = /(<\/?(?:[a-z][a-z0-9]*:)?[a-z][a-z0-9-_.]*?[a-z0-9]*\s*(?:\s+[a-z0-9-_:]+(?:=(?:(?:'[\s\S]*?')|(?:"[\s\S]*?")))?)*\s*\/?>)|([^<]|<(?![a-z/]))*/gi;
var attrRegExp = /\s[a-z0-9-_:]+\b(\s*=\s*('|")[\s\S]*?\2)?/gi;
var splitAttrRegExp = /(\s[a-z0-9-_:]+\b\s*)(?:=(\s*('|")[\s\S]*?\3))?/gi;
var startTagExp = /^<[a-z]/;
var selfCloseTagExp = /\/>$/;
var closeTagExp = /^<\//;
var textNodeExp = /^[^<]/;
var nodeNameExp = /<\/?((?:([a-z][a-z0-9]*):)?(?:[a-z](?:[a-z0-9-_.]*[a-z0-9])?))/i;
var attributeQuotesExp = /^('|")|('|")$/g;
var noClosingTagsExp = /^(?:area|base|br|col|command|embed|hr|img|input|link|meta|param|source)/i;

function Dom(rawHTML) {
    this.rawHTML = rawHTML;
}
Dom.prototype.find = function(conditionFn, findFirst) {
    var result = find(this.rawHTML, conditionFn, findFirst);
    return findFirst ? result[0] || null : result;
}
Dom.prototype.getElementsByClassName = function(className) {
    var expr = new RegExp('^(.*?\\s)?' + className + '(\\s.*?)?$');
    return this.find(function (node) { return Boolean(node.attributes.length && expr.test(node.getAttribute('class') || '')) });
}
Dom.prototype.getElementsByTagName = function(tagName) {
    return this.find(function (node) { return node.nodeName.toUpperCase() === tagName.toUpperCase() });
}
Dom.prototype.getElementById = function(id) {
    return this.find(function (node) { return node.getAttribute('id') === id, true });
}
Dom.prototype.getElementsByName = function(name) {
    return this.find(function (node) { return node.getAttribute('name') === name });
}
Dom.prototype.getElementsByAttribute = function(attributeName, attributeValue) {
    return this.find(function (node) { return node.getAttribute(attributeName) === attributeValue });
}

// private
function find(html, conditionFn, onlyFirst) {
    var result = [];
    domGenerator(html, function(node) {
        if (node && conditionFn(node)) {
            result.push(node);
            if (onlyFirst) {
                return true;
            }
        }
        return false;
    });
    return result;
}
function domGenerator(html, callback) {
    var tags = getAllTags(html);
    var cursor = null;
    for (var i = 0, l = tags.length; i < l; i++) {
        var tag = tags[i];
        var node = createNode(tag, cursor);
        cursor = node || cursor;
        if (isElementComposed(cursor, tag)) {
            if (callback(cursor)) return;
            cursor = cursor.parentNode;
        }
    }
    while (cursor) {
        if (callback(cursor)) return;
        cursor = cursor.parentNode;
    }
}
function isElementComposed(element, tag) {
    if (!tag) {
        return false;
    }
    var isCloseTag = closeTagExp.test(tag);
    var tagMatch = tag.match(nodeNameExp)
    var nodeName = ((tagMatch && tagMatch.length > 1) ? tagMatch[1] : []) || [];
    var isElementClosedByTag = isCloseTag && element.nodeName === nodeName;
    return isElementClosedByTag || element.isSelfCloseTag || element.nodeType === NodeType.text;
}
function getAllTags(html) {
    return html.match(tagRegExp) || [];
}
function createNode(tag, parentNode) {
    var isTextNode = textNodeExp.test(tag);
    var isStartTag = startTagExp.test(tag);
    if (isTextNode) {
        return createTextNode(tag, parentNode);
    }
    if (isStartTag) {
        return createElementNode(tag, parentNode);
    }
    return null;
}
function createElementNode(tag, parentNode) {
    var _a;
    var tagMatch = tag.match(nodeNameExp)
    var nodeName = ((tagMatch && tagMatch.length > 1) ? tagMatch[1] : []) || [];
    var namespace = ((tagMatch && tagMatch.length > 2) ? tagMatch[2] : []) || [];
    var selfCloseTag = selfCloseTagExp.test(tag) || noClosingTagsExp.test(nodeName);
    var attributes = parseAttributes(tag);
    var elementNode = new Node(
        NodeType.element,
        namespace,
        selfCloseTag,
        undefined,
        nodeName,
        [], // childNodes
        parentNode,
        attributes
    );
    (_a = parentNode === null || parentNode === void 0 ? void 0 : parentNode.childNodes) === null || _a === void 0 ? void 0 : _a.push(elementNode);
    return elementNode;
}
function parseAttributes(tag) {
    return (tag.match(attrRegExp) || []).map(function(attributeString) {
        splitAttrRegExp.lastIndex = 0;
        var exec = splitAttrRegExp.exec(attributeString) || [];
        var name = exec[1] || ''
        var value = exec[2] || ''
        return new NodeAttribute(name.trim(), value.trim().replace(attributeQuotesExp, ''));
    });
}
function createTextNode(text, parentNode) {
    var _a;
    var textNode = new Node(
        NodeType.text,
        undefined,
        undefined,
        text,
        '#text', // nodeName
        undefined, // childNodes
        parentNode
    );
    (_a = parentNode === null || parentNode === void 0 ? void 0 : parentNode.childNodes) === null || _a === void 0 ? void 0 : _a.push(textNode);
    return textNode;
}
