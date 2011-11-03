var ntxtTree = null;
var tagFilter = ''
var textFilter = ''

function wikiText(txt) {
  txt = txt.replace(/^\s*====== (.*) ======/g, '<h6 class="ntxt_h">$1</h6>')
  txt = txt.replace(/^\s*===== (.*) =====/g, '<h5 class="ntxt_h">$1</h5>')
  txt = txt.replace(/^\s*==== (.*) ====/g, '<h4 class="ntxt_h">$1</h4>')
  txt = txt.replace(/^\s*=== (.*) ===/g, '<h3 class="ntxt_h">$1</h3>')
  txt = txt.replace(/^\s*== (.*) ==/g, '<h2 class="ntxt_h">$1</h2>')
  txt = txt.replace(/^\s*= (.*) =/g, '<h1 class="ntxt_h">$1</h1>')
  txt = txt.replace(/(https?:\/\/\S*)/g, '<a href="$1">$1</a>')
  return txt
}

function printTree(n, element) {
  
  var html = ""
  
  n.rootBlock.walkText( 
    function(txt, depth, node) {
    
      if (txt == null || txt.length == 0) {
        return;
      }
      
      txt = wikiText(txt)
      
      if (tagFilter.length > 0 
         && node.tags.join(',').indexOf(tagFilter) >= 0) 
      {
        html += txt
      } else if (textFilter.length > 0 && txt.indexOf(textFilter) >= 0) {
        html += txt
      } else if (tagFilter.length == 0 && textFilter.length == 0) {
        html += txt
      }
      
    },
    function(depth, node) {
      html += '<div class="ntxt ntxt_hidden ntxt_'+depth+'"  name="block_div_plus" '
              + 'style="display:none;z-index:'+depth+'" >'
              + node.text().substr(0, 20) + '...'
              + '</div>'
      html += '<div class="ntxt ntxt_displayed ntxt_'+depth+'" name="block_div" '
              + 'title="Tags: '+node.tags.join(', ')+'" '
              + 'style="display:block;z-index:'+depth+'" '
              +'">'

      html += '<pre class="ntxt ntxt_displayed ntxt_'+depth+'">'
    },
    function(depth, node) {
      html += '</pre>'
      html += '</div>'
    } )
    
  element.innerHTML = html
  
  function leftBorderToggle(e) {
    if ( e.ctrlKey ) {
      
      if ( e.currentTarget.style['border-left-style'] == 'solid' ) {
        e.currentTarget.style['border-left-style'] = 'none'
      } else {
        e.currentTarget.style['border-left-style'] = 'solid'
      }
      
      e.stopPropagation()
    }
  }
  
  var a = document.getElementsByName('block_div')
  for ( var i=0; i < a.length; i+=1 ) {
    if ( a[i].tagName == 'DIV' ) {
      a[i].addEventListener('click', leftBorderToggle)
      a[i].addEventListener( 'dblclick', toggleVisibility)
      a[i].id = "block_div_"+i
    }
  }
  var a = document.getElementsByName('block_div_plus')
  for ( var i=0; i < a.length; i+=1 ) {
    if ( a[i].tagName == 'DIV' ) {
      a[i].addEventListener( 'dblclick', toggleVisibility)
      a[i].id = "block_div_"+i+"_plus"
    }
  }

}

function searchBlocks(){
  var v = document.getElementById('searchType').value
  var i = document.getElementById('searchInput').value
  if ( v == 'tags' ) {
    textFilter = ''
    tagFilter = i
  } else if ( v == 'text' ) {
    textFilter = i
    tagFilter = ''
  } else {
    textFilter = ''
    tagFilter = ''
  }
  
  
  printTree(ntxtTree, document.getElementById('ntxtDiv'));
}


function toggleVisibility(event) {
  event.stopPropagation()
  //event.preventDefault()
  var e = event.currentTarget
  var e2
  
  // Using the event ID, choose the "other" div object. 
  if ( /_plus$/.test( e.id ) ) {
    e2 = document.getElementById(e.id.substr(0, e.id.length-5))
  } else {
    e2 = document.getElementById(e.id+"_plus")
  }
  

  if ( e.style.display == 'none' ) {
    e.style.display = 'block'
    e2.style.display= 'none'
  } else {
    e.style.display = 'none'
    e2.style.display = 'block'
  }
}

function loadNtxt() {
  ntxtTree = ntxt.fetchNtxt(document.getElementById('ntxtFile').value)
}

window.addEventListener('load', function(e) {
  
  loadNtxt()
  
  document.getElementById('ntxtFile').addEventListener('change', loadNtxt)

  printTree(ntxtTree, document.getElementById('ntxtDiv'));
  
  document.getElementById('searchInput').focus()

  var tagHash = {}
  
  for( var i in ntxtTree.rootBlock.tags ) {
    tagHash[ntxtTree.rootBlock.tags[i]]=1
  }
  
  document.getElementById('allTags').innerHTML = 
    Object.keys(tagHash).sort().join(', ')

  document.addEventListener('keypress', function(e) {

    // Do not show help when the user touches input tags.
    if ( e.target.tagName == 'INPUT' ) {
      return
    }

    var c = String.fromCharCode(e.keyCode)

    if ( c == '?' ) {
      alert('help');
    }
  } ) // document.addEventListener
  
  document.getElementById( 'searchInput' ).
           addEventListener('keyup', function() {
             searchBlocks()
           } )
  
  if ( ! ( toc && toc.buildToc ) ) {
    console.error("toc.js is required to be included before this js.")
  } else {           
    // FIXME - make this conditional / popup dialog?
    //toc.buildToc('toc')
  }

})

