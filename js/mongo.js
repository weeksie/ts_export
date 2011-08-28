
var users         = db.users;
var conversations = db.conversations;
var forums        = db.forums;
var posts         = db.posts;
var community     = db.communities.findOne();
//[ users, conversations, forums, posts ].map(function(c) { return c.drop(); });

conversations.update({}, { $set: { community_id: community._id } }, false, true);
forums.update({}, { $set: { community_id: community._id } }, false, true);


posts.ensureIndex({ author_id: 1 });
posts.ensureIndex({ conversation_id: 1 });
conversations.ensureIndex({ forum_id: 1 });

forums.find().forEach(function(forum) {
    conversations.update({ forum_id: forum.twelvestone_id },
                            { $set: { forum_id: forum._id } }, false, true);
});

users.find().forEach(function(user) {
    posts.update({ author_id: user.twelvestone_id },
                 { $set: {
                     author: {
                         original_id: user._id,
                         name: user.name,
                         slug: user.slug
                     }
                 }}, false, true);
});

conversations.find().forEach(function(conv){
    posts.update({ conversation_id: conv.twelvestone_id },
                 { $set: { conversation_id: conv._id } }, false, true);
    
    if(posts.count({ conversation_id: conv._id }) > 0) {
        var fp   = posts.find({ conversation_id: conv._id }, { author: 1 }).sort({ created_at:  1 }).limit(1)[0];
        var lp   = posts.find({ conversation_id: conv._id }, { author: 1 }).sort({ created_at: -1 }).limit(1)[0];
        
        conversations.update({ _id: conv._id },
                             { $set: {
                                 first_post: {
                                     original_id: fp._id,
                                     author: fp.author
                                 },
                                 last_post: {
                                     original_id: lp._id,
                                     author: lp.author
                                 }
                             }}, false, true);
    }
});
