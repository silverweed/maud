# <img> fixes
fromList(document.querySelectorAll "img").map (e) ->
    # ALT fix - Set titles to alt text (xkcd style)
    e.title = e.alt if e.alt != ""

# Handle hash changes
window.onhashchange = () ->
    return unless location.hash.length > 0
    # Post selected
    if location.hash[1] is 'p'
        o.className = o.className.replace "post-selected", "" for o in document.querySelectorAll ".post-selected"
        doc = document.querySelector location.hash
        doc.className = "post post-selected" if doc?
    return

window.onhashchange()

# Fix greentext on old posts
#TODO: move this to server parsing
fromList(document.querySelectorAll ".type blockquote p").map (e) ->
    e.innerHTML = "> " + e.innerHTML.split("\n").join "<br />> "

# Make page lists
pageDivs = document.querySelectorAll ".pages"
for pageDiv in pageDivs
    page = parseInt pageDiv.dataset.current
    baseurl = stripPage location.pathname
    maxstr = pageDiv.dataset.max
    more = pageDiv.dataset.more
    # Do Next/Previous only when we don't know the number of pages
    if maxstr == "nomax"
        pageHTML = ""
        if page > 1
            pageHTML += "<a href=\"#{baseurl}/page/#{page - 1}\">&laquo; Back</a> "
        pageHTML += "<b>#{page}</b>"
        if more == "yes"
            pageHTML += " <a href=\"#{baseurl}/page/#{page + 1}\">Next &raquo;</a>"
        pageDiv.innerHTML = pageHTML
    else
        max = parseInt maxstr
        if max > 1
            pageHTML = "PAGE &nbsp;"
            pageHTML += (if page == n then "<b>#{n}</b> " else "<a href=\"#{baseurl}/page/#{n}\">#{n}</a> ") for n in [1..max]
            pageDiv.innerHTML = pageHTML

# Count remaining characters in a post
charsCount = (id) ->
    form = document.getElementById id
    if form?
        text = document.querySelector("##{id} textarea")
        div = document.querySelector("##{id} .chars-count")
        text.onkeyup = () ->
            remaining = div.dataset.maxlen - text.value.length
            div.innerHTML = "#{remaining} characters left"
            div.style.padding = "0 0 0.5em 0"
            text.style.borderColor = if remaining < 0 then "#E33" else ""
    return

charsCount "prev-form"

window.charsCount = charsCount

# Setup Safe mode button
safeButton = document.getElementById "safeBtn"
filter = window.getFilter()
if "nsfw" in filter
    safeButton.innerHTML = "EXIT SAFE MODE"
    safeButton.style.boxShadow = "0 0 0 1px green inset"
    safeButton.onclick = () ->
        status = window.removeFilter ["nsfw"]
        location.reload()
        return
else
    safeButton.style.boxShadow = "0 0 0 1px darkred inset"
    safeButton.onclick = () ->
        status = window.addFilter ["nsfw"]
        if status == false
            alert "Cookies are not enabled, Safe mode couldn't be enabled"
        location.reload()
        return

# Setup toggle buttons in light mode
lightimagebtn = document.querySelectorAll ".toggleImage"
for imgbtn in lightimagebtn
    imgbtn.onclick = () ->
        url = imgbtn.dataset.url
        imgbtn.outerHTML = "<a href=\"#{url}\"><img src=\"#{url}\" /></a>"
lightiframebtn = document.querySelectorAll ".toggleIframe"
for iframebtn in lightiframebtn
    iframebtn.onclick = () ->
        url = iframebtn.dataset.url
        imgbtn.outerHTML = "<iframe src=\"url\"></iframe>"