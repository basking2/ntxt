
// Build a table of contents from h tags.
// This will decorate the document with anchors of the id format toc_id_<num>.
toc = {

  // Return an HTML table.
  buildTocHtml : function() {
    var idCount = 0
    var nodeList = []
    var tocTxt = ''
    var level = 0
    
    for( var i = 1 ; i <= 6; i+=1 ) {
      var hList = document.getElementsByTagName('h'+i)
      for( var j = 0; j < hList.length; j+=1 ) {
        nodeList.push( hList[j] )
      }
    }
    
    nodeList.sort( function(x,y) { return x.offsetTop > y.offsetTop } )

    for( var i in nodeList ) {
      var eleId = 'toc_id_'+idCount
      var ele = nodeList[i]
      idCount += 1
      
      if ( ele.tagName > 'H'+level ) {
        level += 1
        tocTxt += '<ol>'
      } else if ( ele.tagName < 'H'+level ) {
        level -= 1
        tocTxt += '</ol>'
      }

      tocTxt += '<li><a href="#'+eleId+'">'+ele.innerHTML+'</a></li>'

      if ( ! document.getElementById( eleId ) ) {
        var a = document.createElement('a')
        a.name = eleId
        a.id = eleId
        if ( ele.parentElement ) {
          ele.parentElement.insertBefore(a, ele)
        } else if ( ele.parentNode ) {
          ele.parentNode.insertBefore(a, ele)
        }
        //ele.appendChild(a)
      }
                      
    }
    
    for( ; level > 0; level-= 1) {
      tocTxt += '</ol>'
    }
    
    return tocTxt
  },
  
  // Build and insert the table of contents into an HTML element.
  buildToc: function(tocId) {
    document.getElementById(tocId).innerHTML = toc.buildTocHtml()
  }
}

