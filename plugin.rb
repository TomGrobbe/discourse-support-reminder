# name: discourse-support-reminder
# about: Notifies the user when creating a support topic that support is provided by the community.
# version: 0.0.1
# authors: Tom Grobbe
# url: https://github.com/TomGrobbe/discourse-support-reminder

enabled_site_setting :discourse_support_reminder_enabled

require_dependency 'post_creator'
require_dependency 'topic_creator'


after_initialize do

    module ::SupportReminder; end

    module ::SupportReminder::WebHookTopicViewSerializerExtensions
        def include_post_stream?
            true
        end
    end

    module ::SupportReminder::PostCreatorExtensions
        def initialize(user, opts)
            super
        end
    end

    class ::PostCreator
        prepend ::SupportReminder::PostCreatorExtensions
    end

    class ::WebHookTopicViewSerializer
        prepend ::SupportReminder::WebHookTopicViewSerializerExtensions
    end

    DiscourseEvent.on(:topic_created) do |topic, post, user|
        if enabled_site_setting 
            topics_posted = 0
            # max_posts_allowed = SiteSetting.discourse_topic_limit_max_posts
            # if !max_posts_allowed
                # max_posts_allowed = 1
            # end
            target_categories = SiteSetting.discourse_support_reminder_categories_names.split("|")
            
            if target_categories and target_categories != "" and target_categories != "none"
                reminder_message = SiteSetting.discourse_support_reminder_message
                if !reminder_message or reminder_message == ""
                    reminder_message = "Hi there.<br>Please note that (most) support on this site is provided by the FiveM community. You might not receive a reply on this topic if the community or FiveM staff members are unable to assist you.<br>To improve your chances of a reply, please provide as much information as possible about the issue(s) you are having, and use the support template if possible.<br>Thanks :mascot:"
                end
                target_categories.each do |target_category|
                    ignore_staff = SiteSetting.discourse_support_reminder_excempt_staff
                    if (ignore_staff == true and !user.staff?) or (!ignore_staff)
                        if target_category.to_s == topic.category_id.to_s
                            already_reminded_before = false
                            user.topics.each do |usertopic|
                                if usertopic.category_id == topic.category_id and !usertopic.closed?
                                    topics_posted += 1
                                    if topics_posted > 1
                                        already_reminded_before = true
                                    end
                                end
                            end
                            if !already_reminded_before
                                PostCreator.create!(Discourse.system_user.id, topic_id: topic.id, raw: reminder_message.to_s)
                                # topic.update_status("visible", false, Discourse.system_user)
                                # topic.update_status("closed", true, Discourse.system_user, message: reminder_message.to_s)
                                # if SiteSetting.discourse_topic_limit_auto_delete_topic
                                    # topic.topic_timers=[TopicTimer.create(execute_at: DateTime.now + 24.hours, status_type: 4, user_id: Discourse.system_user.id, topic_id: topic.id, based_on_last_post: false, created_at: DateTime.now, updated_at: DateTime.now, public_type: true)]
                                # end
                            end
                        end
                    end
                end
            end
        end
    end
end