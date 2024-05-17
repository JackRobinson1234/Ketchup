# Welcome to Cloud Functions for Firebase for Python!
# To get started, simply uncomment the below code or create your own.
# Deploy with `firebase deploy`
from firebase_functions import firestore_fn, https_fn
from google.cloud.firestore import DocumentSnapshot, FieldFilter
from google.cloud import firestore
from google.cloud import storage
import firebase_admin
from firebase_functions.firestore_fn import (
  on_document_created,
  on_document_deleted,
  on_document_updated,
  on_document_written,
  Event,
  Change,
  DocumentSnapshot,
)
from firebase_functions import scheduler_fn
# The Firebase Admin SDK to access Cloud Firestore.
from firebase_admin import initialize_app, firestore
import uuid
from firebase_admin import storage as admin_storage, credentials, firestore
from datetime import datetime, timedelta


app = initialize_app()
firestore_client = firestore.client()
storage_client = storage.Client()
bucket_name = "foodi-v1-e989b.appspot.com"
bucket = storage_client.get_bucket(bucket_name)


from urllib.parse import urlparse, unquote

#Extracts the cloud storage file path for the particular folder from a downloadURL
def extract_file_path(download_url, folder):
    parsed_url = urlparse(download_url)
    path = parsed_url.path
    parts = unquote(path).split('/')
    index = parts.index(folder) if folder in parts else -1
    if index != -1:
        file_path = '/'.join(parts[index:])
        return file_path
    return None




################################## Activity ####################################
@on_document_created(document="posts/{id}")
def createPostUpdateActivity(event: Event[DocumentSnapshot]) -> None:
  # Get a dictionary representing the document
  # e.g. {'name': 'Marie', 'age': 66}
  post_dict = event.data.to_dict()
  print(post_dict)
  # Access a particular field as you would any dictionary

  postUid = post_dict["user"].get("id", None)
  postUsername = post_dict["user"].get("username", None)
  postPrivateMode= post_dict["user"].get("privateMode", None)
  postId = post_dict.get("id", None)
  postThumbnail = post_dict.get("thumbnailUrl", None)
  postType = post_dict.get("postType", None)
  profileImageUrl = post_dict["user"].get("profileImageUrl", None)
  if postType == "restaurant":
    name = post_dict.get("restaurant").get("name", None)
    restaurantId = post_dict.get("id", None)
  elif postType == "atHome":
    recipe = post_dict.get("recipe")
    if recipe:
        name = recipe.get("name", "")
    else:
        name = ""
  else:
    name = ""

  print(postUid)
  print(postId)
  if not postPrivateMode:
  # Perform more operations ...
    generated_id = str(uuid.uuid4())
    notification = {
          "id": generated_id, 
          'uid': postUid,
          'postId': postId,
          'type': 0,
          'timestamp': firestore.SERVER_TIMESTAMP,
          'image': postThumbnail,
          'username': postUsername,
          'postType': postType,
          'name': name,
          'profileImageUrl': profileImageUrl
      }
    if postType == "restaurant":
      notification['restaurantId'] = restaurantId
    activity_ref = firestore_client.collection('activity')
    activity_ref.document(generated_id).set(notification)
    print('Notification created:', notification)


@on_document_created(document="collections/{id}")
def createCollectionUpdateActivity(event: Event[DocumentSnapshot]) -> None:
  # Get a dictionary representing the document
  # e.g. {'name': 'Marie', 'age': 66}
  collection_dict = event.data.to_dict()
  print(collection_dict)
  # Access a particular field as you would any dictionary
  uid = collection_dict["uid"]
  username = collection_dict["username"]
  collectionId = collection_dict.get("id", None)
  coverImage = collection_dict.get("coverImageUrl", None)
  name = collection_dict.get("name", None)
  profileImageUrl = collection_dict.get("profileImageUrl", None)

  print(collectionId)
  print(collectionId)
  
  # Perform more operations ...
  if not collection_dict["privateMode"]:
    generated_id = str(uuid.uuid4())
    notification = {
          "id": generated_id, 
          'uid': uid,
          'collectionId': collectionId,
          'type': 1,
          'timestamp': firestore.SERVER_TIMESTAMP,
          'image': coverImage,
          'name': name,
          'username': username,
          'profileImageUrl': profileImageUrl
      }
    notifications_ref = firestore_client.collection('activity')
    notifications_ref.document(generated_id).set(notification)
    print('Notification created:', notification)


@on_document_created(document="collections/{collectionId}/items/{itemId}")
def addCollectionItemActivity(event: Event[DocumentSnapshot]) -> None:
  # Get a dictionary representing the document
  # e.g. {'name': 'Marie', 'age': 66}
  item_dict = event.data.to_dict()
  print(item_dict)
  # Access a particular field as you would any dictionary
  collectionId = item_dict.get("collectionId", None)
  parent_ref = firestore_client.collection('collections').document(collectionId)
  parent_dict = parent_ref.get().to_dict()
  username = parent_dict.get("username", None)
  uid = parent_dict["uid"]
  name = item_dict.get("name", None)
  coverImage = parent_dict.get("coverImageUrl", None) 
  postType = item_dict.get("postType", None)
  profileImageUrl = parent_dict.get("profileImageUrl", None)
  if postType == "restaurant":
    restaurantId = item_dict.get("id", None)
  elif postType == "atHome":
    postId = item_dict.get("id", None)

  print(collectionId)
  print(postType)
  
  if not parent_dict["privateMode"]:
    generated_id = str(uuid.uuid4())
    notification = {
          "id": generated_id, 
          'uid': uid,
          'collectionId': collectionId,
          'type': 2,
          'timestamp': firestore.SERVER_TIMESTAMP,
          'image': coverImage,
          'name': name,
          'username': username,
          'postType': postType,
          'profileImageUrl': profileImageUrl
          
      }
    if postType == "restaurant":
      notification['restaurantId'] = restaurantId
    elif notification['postType'] == "atHome":
      notification['postId'] = postId

    notifications_ref = firestore_client.collection('activity')
    notifications_ref.document(generated_id).set(notification)
    print('Notification created:', notification)

@scheduler_fn.on_schedule(schedule= "every day 00:00")
def deleteOldActivity(event: scheduler_fn.ScheduledEvent) -> None:
    ref = firestore_client.collection("activity")
    # Calculate the cutoff date (2 week ago)
    cutoff_date = datetime.now() - timedelta(days=14)
    # Query for activities older than the cutoff date
    old_activities_query = ref.where(filter = FieldFilter("timestamp", "<", cutoff_date))
    # Delete old activities
    old_activities = old_activities_query.stream()
    for activity in old_activities:
        activity.reference.delete()

   
















############################# Managing Cloud Storage ##############################



@on_document_deleted(document="collections/{collectionId}")
def deleteCollectionCoverPhoto(event: Event[DocumentSnapshot]) -> None:
   collection_dict = event.data.to_dict()
   image_url = collection_dict.get("coverImageUrl")
   if image_url:
    # Extract the bucket name and file name from the old image URL
    file_path =  extract_file_path(image_url, "collection_images")
    blob = bucket.blob(file_path)
    blob.delete()


@on_document_deleted(document="users/{userId}")
def deleteUserProfileImage(event: Event[DocumentSnapshot]) -> None:
   user_dict = event.data.to_dict()
   image_url = user_dict.get("profileImageUrl")
   if image_url:
    # Extract the bucket name and file name from the old image URL
    file_path =  extract_file_path(image_url, "profile_images")
    blob = bucket.blob(file_path)
    blob.delete()


@on_document_deleted(document="posts/{postId}")
def deletePostMedia(event: Event[DocumentSnapshot]) -> None:
  post_dict = event.data.to_dict()
  thumbnailUrl = post_dict.get("thumbnailUrl")
  if thumbnailUrl:
    # Extract the bucket name and file name from the old image URL
    file_path =  extract_file_path(thumbnailUrl, "post_images")
    blob = bucket.blob(file_path)
    blob.delete()
  mediaUrls = post_dict.get("mediaUrls")
  if post_dict.get("mediaType") == "photo":
     for media_url in mediaUrls:
        file_path =  extract_file_path(media_url, "post_images")
        blob = bucket.blob(file_path)
        blob.delete()
  if post_dict.get("mediaType") == "video":
     for media_url in mediaUrls:
        file_path =  extract_file_path(media_url, "post_videos")
        blob = bucket.blob(file_path)
        blob.delete()

     
     
@on_document_updated(document="collections/{id}") 
def deleteChangedCollectionCover(event: Event[DocumentSnapshot]) -> None:
  oldCollection = event.data.before.to_dict()
  newCollection = event.data.after.to_dict()
  image_url = oldCollection.get("coverImageUrl")
  updated_url = newCollection.get("coverImageUrl")
  if image_url != updated_url:
    # Extract the bucket name and file name from the old image URL
    file_path =  extract_file_path(image_url, "collection_images")
    blob = bucket.blob(file_path)
    blob.delete()










############################## Private Mode ######################################
@on_document_updated(document="users/{id}") 
def updatePrivateMode(event: Event[DocumentSnapshot]) -> None:
  oldUser = event.data.before.to_dict()
  updatedUser = event.data.after.to_dict()
  if oldUser["privateMode"] != updatedUser["privateMode"]:
    updated_private_mode = updatedUser["privateMode"]
    uid = updatedUser["id"]
    # Update collections with the same uid
    collections_ref = firestore_client.collection('collections')
    collections_query = collections_ref.where(filter = FieldFilter("uid", "==", uid))
    collections = collections_query.get()
    for collection in collections:
        collection_data = collection.to_dict()
        if collection_data.get('privateMode') != updated_private_mode:
            collection_ref = collections_ref.document(collection.id)
            collection_ref.update({'privateMode': updated_private_mode})

    # Update posts with the same uid
    posts_ref = firestore_client.collection('posts')
    posts_query = posts_ref.where(filter = FieldFilter("user.id", "==", uid))
    posts = posts_query.get()
    for post in posts:
        post_data = post.to_dict()
        if post_data["user"].get('privateMode') != updated_private_mode:
            post_ref = posts_ref.document(post.id)
            post_ref.update({'privateMode': updated_private_mode})

        print(f'Updated private mode for collections and posts of user {uid}')



















  
################################### Edit Profile ####################################

@on_document_updated(document="users/{id}") 
def updateUsername(event: Event[DocumentSnapshot]) -> None:
  oldUser = event.data.before.to_dict()
  updatedUser = event.data.after.to_dict()
  if oldUser["username"] != updatedUser["username"]:
    uid = updatedUser["id"]
    updated_username = updatedUser["username"]

    # Update collections with the same uid
    collections_ref = firestore_client.collection('collections')
    collections_query = collections_ref.where(filter = FieldFilter("uid", "==", uid))
    collections = collections_query.get()
    for collection in collections:
      collection_data = collection.to_dict()
      if collection_data.get('username') != updated_username:
        collection_ref = collections_ref.document(collection.id)
        collection_ref.update({'username': updated_username})

    # Update posts with the same uid
    posts_ref = firestore_client.collection('posts')
    posts_query = posts_ref.where(filter = FieldFilter("user.id", "==", uid))
    posts = posts_query.get()
    for post in posts:
      post_data = post.to_dict()
      if post_data["user"].get('username') != updated_username:
        post_ref = posts_ref.document(post.id)
        post_ref.update({'user.username': updated_username})

    # Update activities with the same uid
    activity_ref = firestore_client.collection('activity')
    activity_query = activity_ref.where(filter = FieldFilter("uid", "==", uid))
    activities = activity_query.get()
    for activity in activities:
      activity_data = activity.to_dict()
      if activity_data.get('username') != updated_username:
        activityId = activity_data["id"]
        activity_ref = activity_query.document(activityId)
        activity_ref.update({'username': updated_username})

    print(f'Updated username for collections, posts, and activities of user {uid}')

      

@on_document_updated(document="users/{id}") 
def updateFullname(event: Event[DocumentSnapshot]) -> None:
  oldUser = event.data.before.to_dict()
  updatedUser = event.data.after.to_dict()
  updated_fullname = updatedUser["fullname"]
  if oldUser["fullname"] != updated_fullname:
    uid = updatedUser["id"]
  # Update collections with the same uid
    collections_ref = firestore_client.collection('collections')
    collections_query = collections_ref.where(filter = FieldFilter("uid", "==", uid))
    collections = collections_query.get()
    for collection in collections:
        collection_data = collection.to_dict()
        if collection_data.get('fullname') != updated_fullname:
              collection_ref = collections_ref.document(collection.id)
              collection_ref.update({'fullname': updated_fullname})

      # Update posts with the same uid
    posts_ref = firestore_client.collection('posts')
    posts_query = posts_ref.where(filter = FieldFilter("user.id", "==", uid))
    posts = posts_query.get()
    for post in posts:
          post_data = post.to_dict()
          if post_data["user"].get('fullname') != updated_fullname:
              post_ref = posts_ref.document(post.id)
              post_ref.update({'user.fullname': updated_fullname})
    print("successfully updated fullname for collections and posts")



@on_document_updated(document="users/{id}") 
def updateProfileImage(event: Event[DocumentSnapshot]) -> None:
  oldUser = event.data.before.to_dict()
  updatedUser = event.data.after.to_dict()
  storage_client = storage.Client()
  updated_profileImageUrl = updatedUser["profileImageUrl"]
  if oldUser["profileImageUrl"] != updated_profileImageUrl:
    uid = updatedUser["id"]
  # Update collections with the same uid
    collections_ref = firestore_client.collection('collections')
    collections_query = collections_ref.where(filter = FieldFilter("uid", "==", uid))
    collections = collections_query.get()
    for collection in collections:
        collection_data = collection.to_dict()
        if collection_data.get('profileImageUrl') != updated_profileImageUrl:
              collection_ref = collections_ref.document(collection.id)
              collection_ref.update({'profileImageUrl': updated_profileImageUrl})

      # Update posts with the same uid
    posts_ref = firestore_client.collection('posts')
    posts_query = posts_ref.where(filter = FieldFilter("user.id", "==", uid))
    posts = posts_query.get()
    for post in posts:
          post_data = post.to_dict()
          if post_data["user"].get('profileImageUrl') != updated_profileImageUrl:
              post_ref = posts_ref.document(post.id)
              post_ref.update({'user.profileImageUrl': updated_profileImageUrl})

    # Update activities with the same uid
    activity_ref = firestore_client.collection('activity')
    activity_query = activity_ref.where(filter = FieldFilter("uid", "==", uid))
    activities = activity_query.get()
    for activity in activities:
      activity_data = activity.to_dict()
      if activity_data.get('profileImageUrl') != updated_profileImageUrl:
        activityId = activity_data["id"]
        activity_ref = activity_query.document(activityId)
        activity_ref.update({'profileImageUrl': updated_profileImageUrl})
    

    # Delete old profile image from storage
    old_profile_image_url = oldUser.get("profileImageUrl")
    print(old_profile_image_url)
    if old_profile_image_url:
        # Extract the bucket name and file name from the old image URL
        file_path =  extract_file_path(old_profile_image_url, "profile_images")
        bucket = storage_client.get_bucket(bucket_name)
        blob = bucket.blob(file_path)
        print(blob)
        blob.delete()

    print(f'Updated profileImage for collections, posts, activity of user {uid}')


























############################### Post Stats ############################

@on_document_created(document="posts/{postId}/post-likes/{userId}")
def increasePostLikeCount(event: Event[DocumentSnapshot]) -> None:
   postId = event.params["postId"]
   post_ref = firestore_client.collection('posts')
   post_ref.document(postId).update({"likes": firestore.Increment(1)})


@on_document_deleted(document="posts/{postId}/post-likes/{userId}")
def decreasePostLikeCount(event: Event[DocumentSnapshot]) -> None:
   postId = event.params["postId"]
   post_ref = firestore_client.collection('posts')
   post_ref.document(postId).update({"likes": firestore.Increment(-1)})

@on_document_created(document="posts/{postId}/post-comments/{commentId}")
def increasePostCommentCount(event: Event[DocumentSnapshot]) -> None:
   comment_dict = event.data.to_dict()
   postId = comment_dict.get("postId")
   post_ref = firestore_client.collection('posts')
   post_ref.document(postId).update({"commentCount": firestore.Increment(1)})

@on_document_deleted(document="posts/{postId}/post-comments/{commentId}")
def decreasePostCommentCount(event: Event[DocumentSnapshot]) -> None:
   comment_dict = event.data.to_dict()
   postId = comment_dict.get("postId")
   post_ref = firestore_client.collection('posts')
   post_ref.document(postId).update({"commentCount": firestore.Increment(-1)})

















################################ Restaurant Stats ##########################################
@on_document_created(document="restaurants/{restaurantId}/collections/{collectionId}")
def increaseRestaurantCollectionCount(event: Event[DocumentSnapshot]) -> None:
  restaurantId = event.params["restaurantId"]
  ref =firestore_client.collection("restaurants").document(restaurantId)
  ref.update({"stats.collectionCount": firestore.Increment(1)})

@on_document_deleted(document="restaurants/{restaurantId}/collections/{collectionId}")
def decreaseRestaurantCollectionCount(event: Event[DocumentSnapshot]) -> None:
  restaurantId = event.params["restaurantId"]
  ref =firestore_client.collection("restaurants").document(restaurantId)
  ref.update({"stats.collectionCount": firestore.Increment(-1)})


@on_document_created(document="posts/{postId}")
def increaseRestaurantPostStat(event: Event[DocumentSnapshot]) -> None:
    post_dict = event.data.to_dict()
    if post_dict.get("privateMode") != True:
      if post_dict.get("postType") == "restaurant":
        restaurantId = post_dict.get("restaurant").get("id")
        ref = firestore_client.collection("restaurants").document(restaurantId)
        ref.update({"stats.postCount": firestore.Increment(1)})


@on_document_deleted(document="posts/{postId}")
def decreaseRestaurantPostStat(event: Event[DocumentSnapshot]) -> None:
    post_dict = event.data.to_dict()
    if post_dict.get("privateMode") != True:
      if post_dict.get("postType") == "restaurant":
        restaurantId = post_dict.get("restaurant").get("id")
        ref = firestore_client.collection("restaurants").document(restaurantId)
        ref.update({"stats.postCount": firestore.Increment(-1)})


















############################# User Stats #################################




@on_document_created(document="followers/{userId}/user-followers/{followerId}")
def increaseFollowerCount(event: Event[DocumentSnapshot]) -> None:
   uid = event.params["userId"]
   print(uid)
   user_ref = firestore_client.collection('users')
   user_ref.document(uid).update({"stats.followers": firestore.Increment(1)})
   print("followers increased")


@on_document_deleted(document="followers/{userId}/user-followers/{followerId}")
def decreaseFollowerCount(event: Event[DocumentSnapshot]) -> None:
   uid = event.params["userId"]
   print(uid)
   user_ref = firestore_client.collection('users')
   user_ref.document(uid).update({"stats.followers": firestore.Increment(-1)})
   print("followers decreased")

@on_document_created(document="following/{userId}/user-following/{followerId}")
def increaseFollowingCount(event: Event[DocumentSnapshot]) -> None:
   uid = event.params["userId"]
   user_ref = firestore_client.collection('users')
   user_ref.document(uid).update({"stats.following": firestore.Increment(1)})

   

@on_document_deleted(document="following/{userId}/user-following/{followerId}")
def decreaseFollowingCount(event: Event[DocumentSnapshot]) -> None:
   uid = event.params["userId"]
   user_ref = firestore_client.collection('users')
   user_ref.document(uid).update({"stats.following": firestore.Increment(-1)})

@on_document_created(document="posts/{postId}")
def increaseUserPostStat(event: Event[DocumentSnapshot]) -> None:
    post_dict = event.data.to_dict()
    uid = post_dict["user"].get("id", None)
    user_ref = firestore_client.collection('users')
    user_ref.document(uid).update({"stats.posts": firestore.Increment(1)})

@on_document_deleted(document="posts/{postId}")
def decreaseUserPostStat(event: Event[DocumentSnapshot]) -> None:
    post_dict = event.data.to_dict()
    uid = post_dict["user"].get("id", None)
    user_ref = firestore_client.collection('users')
    user_ref.document(uid).update({"stats.posts": firestore.Increment(-1)})

@on_document_created(document="collections/{collectionId}")
def increaseUserCollectionStat(event: Event[DocumentSnapshot]) -> None:
    collection_dict = event.data.to_dict()
    uid = collection_dict.get("uid", None)
    user_ref = firestore_client.collection('users')
    user_ref.document(uid).update({"stats.collections": firestore.Increment(1)})

@on_document_deleted(document="collections/{collectionId}")
def decreaseUserCollectionStat(event: Event[DocumentSnapshot]) -> None:
    collection_dict = event.data.to_dict()
    uid = collection_dict.get("uid", None)
    user_ref = firestore_client.collection('users')
    user_ref.document(uid).update({"stats.collections": firestore.Increment(-1)})



























########################### NOTIFICATIONS #################################


@on_document_created(document="posts/{postId}/post-likes/{userId}")
def createLikeNotification(event: Event[DocumentSnapshot]) -> None:
   likingUser = event.params["userId"]
   postId = event.params["postId"]
# Info from the post
   post_ref = firestore_client.collection("posts").document(postId)
   post_dict = post_ref.get().to_dict()
   receivingUid = post_dict.get("user", None).get("id", None)
   thumbnail = post_dict.get("thumbnailUrl", None)
# Info from the user
   if receivingUid != likingUser:
    user_ref = firestore_client.collection("users").document(likingUser)
    user_dict = user_ref.get().to_dict()
    username = user_dict.get("username", None)
    profileImageUrl = user_dict.get("profileImageUrl", None)
    generated_id = str(uuid.uuid4())
    
    notification = {
            "id": generated_id, 
            'uid': likingUser,
            'postId': postId,
            'type': 0,
            'timestamp': firestore.SERVER_TIMESTAMP,
            'postThumbnail': thumbnail,
            'username': username,
            'profileImageUrl': profileImageUrl
        }
    
    notifications_ref = firestore_client.collection('notifications')
    notifications_ref.document(receivingUid).collection('user-notifications').document(generated_id).set(notification)

@on_document_created(document="posts/{postId}/post-comments/{commentId}")
def createCommentNotification(event: Event[DocumentSnapshot]) -> None:
   comment_dict = event.data.to_dict()
   commentingUser = comment_dict["commentOwnerUid"]
   postId = comment_dict["postId"]
   print(commentingUser)
   print(postId)
# Info from the post
   post_ref = firestore_client.collection("posts").document(postId)
   post_dict = post_ref.get().to_dict()
   print(post_dict)
   receivingUid = post_dict["user"].get("id", None)
   thumbnail = post_dict.get("thumbnailUrl", None)
# Info from the user
   if receivingUid != commentingUser:
    user_ref = firestore_client.collection("users").document(commentingUser)
    user_dict = user_ref.get().to_dict()
    print(user_dict)
    username = user_dict.get("username", None)
    profileImageUrl = user_dict.get("profileImageUrl", None)
    generated_id = str(uuid.uuid4())
    
    notification = {
            "id": generated_id, 
            'uid': commentingUser,
            'postId': postId,
            'type': 1,
            'timestamp': firestore.SERVER_TIMESTAMP,
            'postThumbnail': thumbnail,
            'username': username,
            'profileImageUrl': profileImageUrl
        }
    
    notifications_ref = firestore_client.collection('notifications')
    notifications_ref.document(receivingUid).collection('user-notifications').document(generated_id).set(notification)


@on_document_created(document="followers/{userId}/user-followers/{followerUserId}")
def createfollowingNotification(event: Event[DocumentSnapshot]) -> None:
  followingUser = event.params["followerUserId"]
  user = event.params["userId"]
# Info from the followingUser
  user_ref = firestore_client.collection("users").document(followingUser)
  user_dict = user_ref.get().to_dict()
  username = user_dict.get("username", None)
  profileImageUrl = user_dict.get("profileImageUrl", None)
  generated_id = str(uuid.uuid4())

  notification = {
        "id": generated_id, 
        'uid': followingUser,
        'type': 2,
        'timestamp': firestore.SERVER_TIMESTAMP,
        'username': username,
        'profileImageUrl': profileImageUrl
    }

  notifications_ref = firestore_client.collection('notifications')
  notifications_ref.document(user).collection('user-notifications').document(generated_id).set(notification)








############################ Restaurant Collections ##################################
@on_document_created(document="collections/{collectionId}/items/{itemId}")
def addCollectionToRestaurant(event: Event[DocumentSnapshot]) -> None:
  item_dict = event.data.to_dict()
  privateMode = item_dict.get("privateMode")
  if privateMode != True:
    collectionId = item_dict.get("collectionId")
    if item_dict.get("postType") == "restaurant":
      restaurantId = event.params["itemId"]
      ref =firestore_client.collection("restaurants").document(restaurantId).collection("collections")
      ref.document(collectionId).set({})

@on_document_deleted(document="collections/{collectionId}/items/{itemId}")
def removeCollectionFromRestaurant(event: Event[DocumentSnapshot]) -> None:
  item_dict = event.data.to_dict()
  collectionId = item_dict.get("collectionId")
  if item_dict.get("postType") == "restaurant":
    restaurantId = event.params["itemId"]
    ref = firestore_client.collection("restaurants").document(restaurantId).collection("collections")
    ref.document(collectionId).delete()





############################ Deleting Objects Maintenance ###########################
@on_document_deleted(document="collections/{collectionId}")
def deleteCollectionItems(event: Event[DocumentSnapshot]) -> None: 
   collectionId = event.params["collectionId"]
   items_ref = firestore_client.collection('collections').document(collectionId).collection("items")
   # Delete all documents in the items subcollection
   batch = firestore_client.batch()
   for doc in items_ref.stream():
        batch.delete(doc.reference)
   batch.commit()

@on_document_deleted(document="collections/{collectionId}")
def deleteCollectionActivity(event: Event[DocumentSnapshot]) -> None: 
   collectionId = event.params["collectionId"]
   items_ref = firestore_client.collection('activity').where(filter = FieldFilter("collectionId", "==", collectionId))
   # Delete all documents in the items subcollection
   batch = firestore_client.batch()
   for doc in items_ref.stream():
        batch.delete(doc.reference)
   batch.commit()

@on_document_deleted(document="posts/{postId}")
def deletePostLikes(event: Event[DocumentSnapshot]) -> None: 
   postId = event.params["postId"]
   items_ref = firestore_client.collection('posts').document(postId).collection("post-likes")
   # Delete all documents in the items subcollection
   batch = firestore_client.batch()
   for doc in items_ref.stream():
        user_id = doc.id
        batch.delete(doc.reference)
        user_profile_ref = firestore_client.collection('users').document(user_id).collection('user-likes').document(postId)
        user_profile_ref.delete()
   batch.commit()

@on_document_deleted(document="posts/{postId}")
def deletePostComments(event: Event[DocumentSnapshot]) -> None: 
   postId = event.params["postId"]
   items_ref = firestore_client.collection('posts').document(postId).collection("post-comments")
   # Delete all documents in the items subcollection
   batch = firestore_client.batch()
   for doc in items_ref.stream():
        batch.delete(doc.reference)
   batch.commit()

@on_document_deleted(document="posts/{postId}")
def deletePostActivity(event: Event[DocumentSnapshot]) -> None: 
   postId = event.params["postId"]
   items_ref = firestore_client.collection('activity').where(filter = FieldFilter("postId", "==", postId))
   # Delete all documents in the items subcollection
   batch = firestore_client.batch()
   for doc in items_ref.stream():
      batch.delete(doc.reference)
   batch.commit()
   