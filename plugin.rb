# name: discourse-support-reminder
# about: Notifies the user when creating a support topic that support is provided by the community.
# version: 1.0
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
            target_categories = SiteSetting.discourse_support_reminder_categories_names.split("|")
            
            if target_categories and target_categories != "" and target_categories != "none"
                reminder_message = SiteSetting.discourse_support_reminder_message
                if !reminder_message or reminder_message == ""
                    reminder_message = "Hi there, this is a small reminder because it has been a while since you have created a topic in this category.<br><br>Please note that support on these forums are provided by the FiveM community. Because of this, there is a small chance that your topic will not receive any replies to help you out. Sometimes the exact cause of your issue(s) are unknown, and therefor the community or FiveM staff is unable to assist you. To avoid unnecessary/duplicate topics, please browse the forums before creating a topic.<br><br>To improve your chances of a reply, please provide as much information as possible about the issue(s) you are having. Also, whenever possible, use the support template given to you as soon as you create a topic.<br><br>Thanks for helping us keeping these forums tidy! :mascot:"
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
                                PostCreator.create!(Discourse.system_user, topic_id: topic.id, raw: reminder_message.to_s)
                            end
                        end
                    end
                end
            end
        end
    end
end