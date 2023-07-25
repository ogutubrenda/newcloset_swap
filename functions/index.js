/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {onRequest} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const admin = require('firebase-admin');
admin.initializeApp();

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });
exports.onCreateFollower = functions.firestore
.document("/followers/{userId}/userFollowers/{followerId}")
.onCreate(async(snapshot, context) => {
    console.log("Follower Created", snapshot.data());
    const userId = context.params.userId;
    const followerId = context.params.followerId;
    //get followed users posts
    const followedUserRef = admin.firestore().collection('posts')
    .firestore()
    .collection('posts')
    .doc(userId)
    .collection('userPosts');

    //get following users timeline
    const timelinePostsRef = admin
    .firestore()
    .collection('timeline')
    .doc(userId)
    .collection('timelinePosts');

    const querySnapshot =await followedUserPostsFef.get();

    querySnapshot.forEach(doc =>{
        if(doc.exixts){
            const postId = doc.id;
            const postData = doc.data();
            timelinePostsRef.doc(postId).set(postData);
        }
    })

});