/**
 * Import function triggers from their respective submodules:
   const admin = require('firebase-admin')
   admin.initializeApp();
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {onRequest} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });
exports. onCreateFollower = functions.firestore
 .document("/followers/{userid}/userFollowers/{followerId}")
 .onCreate(async (snapshot, context)=> {
    console.log("Follower Created", snapshot.data());
    const userid = context.params.userid;
    const followerId = context.params.followerId;

    //create followed users posts ref
    const followedUserPostRef = admin
    .firestore()
    .collection('posts')
    .doc(userid)
    .collection('userPosts');

    //create Following user's timeline ref
    const timelinePostRef = admin
    .firestore()
    .collection('timeline')
    .doc()
    .collection('timelinePosts');

    //get followed users post
    const querySnapshot = await followedUserPostRef();

    //Add each user post to following user's timeline

    querySnapshot.forEach(doc =>{
        if (doc.exists){
            const postId = doc.id;
            const postData = doc.data();
            timelinePostsRef.doc(postId).set(postData);
        }
    });
 

 });

 exports.onDeleteFollower = functions.firestore
 .document("/followers/{userid}/userFollowers/{followerId}")
 onDelete(async (snapshot, context) =>{
    console.log("Follower Deleted", snapshot. id);

    const userid = context.params. userid;
    const followerId = context.params.followerId;

    const timelinePostsRef = admin
     .firestore()
     .collection("timeline")
     .doc(followerId)
     .collection("timelinePosts")
     .where("ownerId", "==", userid);

     const querySnapshot = await timelinePostsRef.get();
     querySnapshot.forEach(doc =>{
        if (doc.exists){
            doc.ref.delete();
        }
     });
 });

 exports.onCreatePost = functions.firestore
 .document('/posts/{userid}/userPosts/{postId}')
 .onCreate(async (snapshot, context) =>{
   const postCreated = snapshot.data();
   const userid = context.params. userid;
   const postId = context.params. postId;

   //Get all the followers of the users who made the post

   const userFollowersRef = admin.firestore
   .collection('followers')
   .doc(userid)
   .collection('userFollowers');

   const querySnapshot = await userFollowersRef.get();
   // Add new post to each follower's timeline
   querySnapshot. forEach(doc =>{
    const followerId = doc.id;
    
    admin
    .firestore()
    .collection('timeline')
    .doc(followerId)
    .collection('timelinePosts')
    .doc(postId)
    .set(postCreated);
   });

});
exports. onUpdatePost = functions.firestore
.document('/posts/{userid}/userPosts/{postId}')
.onUpdate(async (change, context)=>{
    const postUpdated = change. after.data();
    const userid = context.params.userid;
    const postId = context.params. postId;

    //Get all followers of users who made the post
    const userFollowersRef = admin.firestore()
    .collection('followers')
    .doc(userid)
    .collection('userFollowers');

    const querySnapshot = await userFollowersRef.get();

    //AUpdate each post to each followers timeline
    querySnapshot. forEach(doc =>{
        const followerId = doc.id;
        
        admin
        .firestore()
        .collection('timeline')
        .doc(followerId)
        .collection('timelinePosts')
        .doc(postId)
        .get().then(doc =>{
            if (doc.exists) {
                doc.ref.update(postUpdated);
            }
        });
});  });

exports.onDeletePost = functions.firestore
.document('/posts/{userid}/userPosts/{postId}')
.onDelete(async (snapshot, context)=>{
    const userid = context.params.userid;
    const postId = context.params. postId;
    
    const userFollowersRef = admin.firestore()
    .collection('followers')
    .doc(userid)
    .collection('userFollowers');

    const querySnapshot = await userFollowersRef.get();
    querySnapshot. forEach(doc =>{
        const followerId = doc.id;
        
        admin
        .firestore()
        .collection('timeline')
        .doc(followerId)
        .collection('timelinePosts')
        .doc(postId)
        .get().then(doc =>{
            if (doc.exists) {
                doc.ref.delete();
            }
        });
})  });