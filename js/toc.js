/**
 * Simple table of contents generator. 
 * This does not require any other resources (such as jQuery).
 */
TableOfContents = function(id) {
    document.getElementById(id).innerHTML = this.buildTocHtml();
};

(function(){

  // Return an HTML table.
  this.buildTocHtml = function() {
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
      }
                      
    }
    
    for( ; level > 0; level-= 1) {
      tocTxt += '</ol>'
    }
    
    return tocTxt
  }
}).call(TableOfContents.prototype);

