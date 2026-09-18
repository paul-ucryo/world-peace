/**
 * fed - ui layer
 *
 * assumes 4 nodes exist in whatever rendering context:
 *   #header  - hud / shell env manager
 *   #im      - imaginary: tree editor / live terminal / catalogue page editor
 *   #re      - real: rendered result of what im defines
 *   #footer  - cli: status indicators, search/filter, command input
 *
 * the DOM is one rendering context. so is SVG, canvas, a blender scene.
 * this file reasons over placing content into those 4 nodes.
 * how the user positions and resizes them is not this system's concern.
 *
 * the scene graph is the abstraction.
 * html dom, svg, canvas are just pipelines that render it.
 *
 * looks like a cross between autocad and simulink:
 *   - im is the design tree / configuration editor (solidworks-style)
 *   - re is the live viewport of whatever im defines
 *   - header is the hud - active domain, gw context, identity
 *   - footer is the cli - status, search, filter, command
 */

'use strict';

// --- scene graph ---
// everything is a node in the graph
// nodes have type, address, children, and a .hb (intent/journal)
// the graph is the system state. im edits it. re renders it.

class Node {
  constructor({ type, address, label, children = [], meta = {} }) {
    this.type = type;         // 'domain' | 'file' | 'action' | 'view' | ...
    this.address = address;   // fed.* encoded address
    this.label = label;       // human readable, from .hb or filename
    this.children = children;
    this.meta = meta;         // arbitrary - gw context, acs policy, hb entries
    this._listeners = {};
  }

  on(event, fn) {
    (this._listeners[event] ||= []).push(fn);
    return this;
  }

  emit(event, data) {
    (this._listeners[event] || []).forEach(fn => fn(data));
  }

  append(child) {
    this.children.push(child);
    this.emit('change', { kind: 'append', child });
    return this;
  }

  toJSON() {
    return {
      type: this.type,
      address: this.address,
      label: this.label,
      children: this.children.map(c => c.toJSON()),
      meta: this.meta,
    };
  }
}


// --- catalogue page ---
// every node is a catalogue page object
// a page has: address, type, intent (.hb), config, children
// this is the unit im edits and re renders

class CataloguePage {
  constructor(node) {
    this.node = node;
  }

  // render this page as a scene graph element
  // context determines what kind of element: dom, svg, canvas
  render(context) {
    return context.renderPage(this);
  }

  // read intent from .hb - the why behind this page
  get intent() {
    return this.node.meta.hb || '';
  }

  set intent(text) {
    this.node.meta.hb = text;
    this.node.emit('change', { kind: 'intent', text });
  }
}


// --- rendering contexts ---
// each context knows how to render a scene graph into its medium
// dom, svg, canvas are all valid contexts
// the system doesn't care which one is active

class DOMContext {
  constructor(root) {
    this.root = root; // a DOM element
  }

  renderPage(page) {
    const el = document.createElement('div');
    el.className = `fed-page fed-page--${page.node.type}`;
    el.dataset.address = page.node.address;

    const label = document.createElement('span');
    label.className = 'fed-page__label';
    label.textContent = page.node.label;
    el.appendChild(label);

    if (page.node.children.length) {
      const children = document.createElement('div');
      children.className = 'fed-page__children';
      page.node.children.forEach(child => {
        const childPage = new CataloguePage(child);
        children.appendChild(childPage.render(this));
      });
      el.appendChild(children);
    }

    return el;
  }

  clear() {
    this.root.innerHTML = '';
  }

  mount(el) {
    this.root.appendChild(el);
  }
}


class SVGContext {
  constructor(root) {
    this.root = root; // an SVG element
    this._y = 20;
    this._x = 20;
  }

  renderPage(page, depth = 0) {
    const g = document.createElementNS('http://www.w3.org/2000/svg', 'g');
    g.setAttribute('transform', `translate(${this._x + depth * 16}, ${this._y})`);
    g.dataset.address = page.node.address;

    const rect = document.createElementNS('http://www.w3.org/2000/svg', 'rect');
    rect.setAttribute('width', 180);
    rect.setAttribute('height', 18);
    rect.setAttribute('rx', 2);
    rect.setAttribute('class', `fed-node fed-node--${page.node.type}`);
    g.appendChild(rect);

    const text = document.createElementNS('http://www.w3.org/2000/svg', 'text');
    text.setAttribute('x', 6);
    text.setAttribute('y', 13);
    text.setAttribute('class', 'fed-node__label');
    text.textContent = page.node.label;
    g.appendChild(text);

    this._y += 22;

    page.node.children.forEach(child => {
      const childPage = new CataloguePage(child);
      g.appendChild(this.renderPage(childPage, depth + 1));
    });

    return g;
  }

  clear() {
    while (this.root.firstChild) this.root.removeChild(this.root.firstChild);
    this._y = 20;
  }

  mount(el) {
    this.root.appendChild(el);
  }
}


// --- panels ---
// each of the 4 nodes gets a panel controller
// the panel knows its DOM node and its rendering context
// content placement is the panel's responsibility

class Panel {
  constructor(id) {
    this.el = document.getElementById(id);
    this.id = id;
    if (!this.el) console.warn(`fed: no element found for #${id}`);
  }

  clear() {
    if (this.el) this.el.innerHTML = '';
  }

  append(child) {
    if (this.el) this.el.appendChild(child);
  }

  text(str) {
    if (this.el) this.el.textContent = str;
  }
}


// --- header: hud ---
// active domain, gw context, identity, shell env

class Header extends Panel {
  constructor() {
    super('header');
  }

  render({ domain, address, gw, identity }) {
    this.clear();

    const hud = document.createElement('div');
    hud.className = 'fed-hud';
    hud.innerHTML = `
      <span class="fed-hud__domain" title="active domain">${domain || '—'}</span>
      <span class="fed-hud__address" title="address">${address || ''}</span>
      <span class="fed-hud__gw" title="GW context">${gw || ''}</span>
      <span class="fed-hud__identity" title="identity">${identity || ''}</span>
    `;

    this.append(hud);
  }
}


// --- footer: cli ---
// status indicators, search/filter, command input

class Footer extends Panel {
  constructor(onCommand) {
    super('footer');
    this.onCommand = onCommand;
    this._status = {};
  }

  render() {
    this.clear();

    const cli = document.createElement('div');
    cli.className = 'fed-cli';

    const status = document.createElement('div');
    status.className = 'fed-cli__status';
    status.id = 'fed-status';
    cli.appendChild(status);

    const search = document.createElement('input');
    search.className = 'fed-cli__search';
    search.type = 'text';
    search.placeholder = 'filter...';
    search.addEventListener('input', e => {
      this.onCommand({ kind: 'filter', value: e.target.value });
    });
    cli.appendChild(search);

    const input = document.createElement('input');
    input.className = 'fed-cli__input';
    input.type = 'text';
    input.placeholder = '> command';
    input.addEventListener('keydown', e => {
      if (e.key === 'Enter') {
        this.onCommand({ kind: 'command', value: input.value });
        input.value = '';
      }
    });
    cli.appendChild(input);

    this.append(cli);
  }

  setStatus(key, value) {
    this._status[key] = value;
    const el = document.getElementById('fed-status');
    if (el) {
      el.textContent = Object.entries(this._status)
        .map(([k, v]) => `${k}: ${v}`)
        .join('  |  ');
    }
  }
}


// --- im: imaginary ---
// tree editor / live terminal / vi-like catalogue page editor
// everything stored and accessed as a catalogue page object
// multiple views: tree, journal, config
// like solidworks design tree generalized to full os state

class Im extends Panel {
  constructor(onSelect) {
    super('im');
    this.onSelect = onSelect;
    this.tree = null;
    this.activeView = 'tree'; // 'tree' | 'journal' | 'config'
    this.context = null;
  }

  setTree(rootNode) {
    this.tree = rootNode;
    this.refresh();
  }

  setView(view) {
    this.activeView = view;
    this.refresh();
  }

  refresh() {
    this.clear();
    if (!this.tree) return;

    const toolbar = document.createElement('div');
    toolbar.className = 'fed-im__toolbar';
    ['tree', 'journal', 'config'].forEach(view => {
      const btn = document.createElement('button');
      btn.textContent = view;
      btn.className = `fed-im__view-btn${this.activeView === view ? ' --active' : ''}`;
      btn.addEventListener('click', () => this.setView(view));
      toolbar.appendChild(btn);
    });
    this.append(toolbar);

    const content = document.createElement('div');
    content.className = 'fed-im__content';

    if (this.activeView === 'tree') {
      // SVG scene graph - autocad/simulink style design tree
      const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
      svg.setAttribute('class', 'fed-im__svg');
      svg.setAttribute('width', '100%');
      svg.setAttribute('height', '100%');
      this.context = new SVGContext(svg);
      this.context.clear();
      const page = new CataloguePage(this.tree);
      this.context.mount(this.context.renderPage(page));
      content.appendChild(svg);

    } else if (this.activeView === 'journal') {
      // vi-like editor for .hb intent entries
      const editor = document.createElement('textarea');
      editor.className = 'fed-im__journal';
      editor.placeholder = '.hb - intent, notes, dreams, meeting context...';
      editor.value = this.tree.meta.hb || '';
      editor.addEventListener('change', e => {
        this.tree.meta.hb = e.target.value;
        this.tree.emit('change', { kind: 'intent', text: e.target.value });
      });
      content.appendChild(editor);

    } else if (this.activeView === 'config') {
      // config editor - key/value pairs, monadic inheritance visible
      const table = document.createElement('table');
      table.className = 'fed-im__config';
      const entries = Object.entries(this.tree.meta).filter(([k]) => k !== 'hb');
      entries.forEach(([k, v]) => {
        const row = table.insertRow();
        const key = row.insertCell();
        key.textContent = k;
        key.className = 'fed-im__config-key';
        const val = row.insertCell();
        const input = document.createElement('input');
        input.value = typeof v === 'object' ? JSON.stringify(v) : v;
        input.addEventListener('change', e => {
          this.tree.meta[k] = e.target.value;
          this.tree.emit('change', { kind: 'config', key: k, value: e.target.value });
        });
        val.appendChild(input);
      });
      content.appendChild(table);
    }

    this.append(content);
  }
}


// --- re: real ---
// rendered result of whatever im defines
// multiple windows, connected to one or more trees
// dom renderer by default - but the context is swappable

class Re extends Panel {
  constructor() {
    super('re');
    this.context = null;
    this.windows = []; // multiple views into the same or different trees
  }

  attach(rootNode, contextType = 'dom') {
    const win = { node: rootNode, contextType };
    this.windows.push(win);
    this.refresh();
  }

  refresh() {
    this.clear();
    this.windows.forEach(win => {
      const container = document.createElement('div');
      container.className = 'fed-re__window';

      let context;
      if (win.contextType === 'svg') {
        const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
        svg.setAttribute('width', '100%');
        svg.setAttribute('height', '100%');
        container.appendChild(svg);
        context = new SVGContext(svg);
      } else {
        context = new DOMContext(container);
      }

      const page = new CataloguePage(win.node);
      const rendered = page.render(context);
      if (win.contextType !== 'dom') context.mount(rendered);

      this.append(container);
    });
  }
}


// --- shell ---
// ties the 4 panels together
// handles commands from footer cli
// routes changes from im to re
// manages gw context and active domain

class Shell {
  constructor() {
    this.header = new Header();
    this.footer = new Footer(cmd => this.onCommand(cmd));
    this.im = new Im(node => this.onSelect(node));
    this.re = new Re();

    this.activeNode = null;
    this.gw = [];
  }

  boot(rootNode) {
    this.activeNode = rootNode;

    // listen for tree changes - re renders on any im edit
    rootNode.on('change', () => this.re.refresh());

    this.header.render({
      domain: rootNode.label,
      address: rootNode.address,
      gw: this.gw.join(', ') || 'local',
      identity: rootNode.meta.identity || '—',
    });

    this.footer.render();
    this.footer.setStatus('domain', rootNode.label);
    this.footer.setStatus('address', rootNode.address || '—');

    this.im.setTree(rootNode);
    this.re.attach(rootNode, 'dom');
  }

  onSelect(node) {
    this.im.setTree(node);
    this.footer.setStatus('selected', node.label);
  }

  onCommand({ kind, value }) {
    if (kind === 'command') {
      this.footer.setStatus('last', value);
      // commands extend here - mkdir, hb, gw set, etc.
      console.log('fed cmd:', value);
    } else if (kind === 'filter') {
      this.footer.setStatus('filter', value || '—');
    }
  }
}


// --- init ---
// the shell boots when the 4 nodes exist
// works with whatever html the host provides
// the scene graph is the system - the dom is just one view of it

function fedInit(rootNode) {
  const shell = new Shell();
  shell.boot(rootNode);
  return shell;
}


// --- export ---
// usable as a module or a script
// the host page provides the 4 div nodes and calls fedInit

if (typeof module !== 'undefined') {
  module.exports = { Node, CataloguePage, DOMContext, SVGContext, Shell, fedInit };
} else {
  window.fed = { Node, CataloguePage, DOMContext, SVGContext, Shell, fedInit };
}
