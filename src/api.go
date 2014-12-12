package main

import (
	"fmt"
	"github.com/gorilla/mux"
	"net/http"
	"strings"
)

// apiNewThread: creates a new thread with its OP.
// POST params: title, text, [nickname, tags]
func apiNewThread(rw http.ResponseWriter, req *http.Request) {
	postTitle := req.PostFormValue("title")
	postNickname := req.PostFormValue("nickname")
	postContent := req.PostFormValue("text")
	postTags := req.PostFormValue("tags")
	if len(postTitle) < 1 || len(postContent) < 1 {
		http.Error(rw, "Required fields are missing", 400)
		return
	}

	nickname, tripcode := parseNickname(postNickname)
	user := User{nickname, tripcode}
	content := postContent
	tags := parseTags(postTags)

	threadId, err := DBNewThread(user, postTitle, content, tags)
	if err != nil {
		fmt.Println(err.Error())
		sendError(rw, 500, err.Error())
		return
	}

	http.Redirect(rw, req, "/thread/"+threadId, http.StatusMovedPermanently)
}

// apiReply: appends a post to a thread.
// POST params: text, [nickname]
func apiReply(rw http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	threadUrl := vars["thread"]
	thread, err := DBGetThread(threadUrl)

	postNickname := req.PostFormValue("nickname")
	postContent := req.PostFormValue("text")
	if len(postContent) < 1 {
		http.Error(rw, "Required fields are missing", 400)
		return
	}

	nickname, tripcode := parseNickname(postNickname)
	user := User{nickname, tripcode}
	content := postContent

	_, err = DBReplyThread(&thread, user, content)
	if err != nil {
		fmt.Println(err.Error())
		sendError(rw, 500, err.Error())
		return
	}

	http.Redirect(rw, req, "/thread/"+thread.ShortUrl+"#last", http.StatusMovedPermanently)
}

// apiEditPost: updates the content of a post and its LastModified field
// (auth via tripcode); returns the new content as response so it can
// be used to update the original post via AJAX
// POST params: tripcode, text
func apiEditPost(rw http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	thread, post, err := threadPostOrErr(rw, vars["thread"], vars["post"])
	// if post has no tripcode associated, refuse to edit
	if len(post.Author.Tripcode) < 1 {
		http.Error(rw, "Forbidden", 403)
		return
	}
	// check tripcode
	trip := req.PostFormValue("tripcode")
	if tripcode(trip) != post.Author.Tripcode {
		http.Error(rw, "Invalid tripcode", 401)
		return
	}
	// update post content and date
	newContent := req.PostFormValue("text")
	err = DBEditPost(post.Id, newContent)
	if err != nil {
		http.Error(rw, err.Error(), 500)
		return
	}
	fmt.Fprintf(rw, post.Content)
}

// apiDeletePost: Sets the 'deleted flag' to a post, auth-ing request by tripcode.
// Original post content is retained in DB (for now)
// POST params: tripcode
func apiDeletePost(rw http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	thread, post, err := threadPostOrErr(rw, vars["thread"], vars["post"])
	if err != nil {
		return
	}
	// if post has no tripcode associated, refuse to delete
	if len(post.Author.Tripcode) < 1 {
		http.Error(rw, "Forbidden", 403)
		return
	}
	// check tripcode
	trip := req.PostFormValue("tripcode")
	if tripcode(trip) != post.Author.Tripcode {
		http.Error(rw, "Invalid tripcode", 401)
		return
	}
	// set ContentType to 'deleted'
	post.ContentType = "deleted"
	if err := database.C("posts").UpdateId(post.Id, post); err != nil {
		http.Error(rw, err.Error(), 500)
		return
	}

	http.Redirect(rw, req, "/thread/"+thread.ShortUrl+"#p"+vars["post"], http.StatusMovedPermanently)
}

func apiTagSearch(rw http.ResponseWriter, req *http.Request) {
	tags := req.PostFormValue("tags")
	if len(tags) < 1 {
		// if no tags are specified, go back home
		http.Redirect(rw, req, "/", http.StatusNoContent)
		return
	}
	http.Redirect(rw, req, "/tag/"+strings.ToLower(tags), http.StatusMovedPermanently)
}

// apiGetRaw: retreive the raw content of a post.
// POST params: none
func apiGetRaw(rw http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	_, post, err := threadPostOrErr(rw, vars["thread"], vars["post"])
	if err != nil {
		return
	}
	if post.ContentType == "deleted" {
		http.Error(rw, "Forbidden", 403)
		return
	}
	fmt.Fprintln(rw, post.Content)
}
