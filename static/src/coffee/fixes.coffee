# <img> fixes
fromList(document.querySelectorAll "img").map (e) ->
	# ALT fix - Set titles to alt text (xkcd style)
	e.title = e.alt if e.alt != ""

# Handle hash changes
window.onhashchange = ->
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
makePageLists = ->
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
				# make the pages fit the window width
				width = getViewport().width
				insPage = (i) ->
					pageHTML += (if page == i then "<b>#{i}</b> " else "<a href=\"#{baseurl}/page/#{i}\">#{i}</a> ")
				insDots = -> pageHTML += "..."
				# m = max number of buttons to output (at least 7)
				# we leave 70px for the "PAGE" text and account 30px per button.
				m = Math.max 7, Math.floor((width - 70) / 30)
				if max <= m
					# output all page buttons
					insPage i for i in [1..max]
				else
					switch
						when page < 4
							insPage i for i in [1..page+1]
							insDots()
							insPage max
						when page > max - 2
							insPage 1
							insDots()
							insPage i for i in [page-1..max]
						else
							insPage 1
							a = Math.floor((m-5)/2)
							if page - a <= 2
								insPage i for i in [2..page]
							else
								insDots()
								insPage i for i in [page-a..page]
							if page + a >= max - 1
								insPage i for i in [page+1..max-1]
							else
								insPage i for i in [page+1..page+a]
								insDots()
							insPage max
				pageDiv.innerHTML = pageHTML
makePageLists()
window.onresize = makePageLists

# Count remaining characters in a post
charsCount = (id) ->
	form = document.getElementById id
	if form?
		text = document.querySelector("##{id} textarea")
		div = document.querySelector("##{id} .chars-count")
		text.onkeyup = ->
			remaining = div.dataset.maxlen - text.value.length
			div.innerHTML = "#{remaining} characters left"
			div.style.padding = "0 0 0.5em 0"
			text.style.borderColor = if remaining < 0 then "#E33" else ""
	return

charsCount "reply-form"

window.charsCount = charsCount

# Setup toggle buttons in light mode
lightimagebtn = document.querySelectorAll ".toggleImage"
imgsetup = (btn) ->
	btn.onclick = ->
		url = btn.dataset.url
		btn.outerHTML = "<a href=\"#{url}\"><img src=\"#{url}\" /></a>"
imgsetup imgbtn for imgbtn in lightimagebtn

# Tag search / Fulltext search buttons (in pages which have it)
toggle = document.getElementById "tagsearchbtn"
toggle?.onclick = ->
	toggle.outerHTML = """
    <form id="tagsearch-form" class="ac_wrapper" style="display: inline-block" method="POST" action="#{basepath}tagsearch" onsubmit="this.querySelector('#tagsearch').value = escapeHTML(this.querySelector('#tagsearch').value); return true">
        <input class="ac_input" type="text" name="tags" id="tagsearch" placeholder="Filter by tag" required title="Insert tags (each starting with '#')" autocomplete="off" />
        <input type="submit" value="Search" />
    </form>
	"""
	box = document.getElementById "tagsearch"
	AC.toggleAutocomplete box, "#{basepath}taglist"
	box.focus()

# Unhide post actions to admins
if window.adminMode
	con.style.display = "inline-block" for con in document.querySelectorAll ".postactions"
