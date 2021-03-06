# name: discourse-support-reminder
# about: Notifies the user when creating a support topic that support is provided by the community.
# version: 1.1
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
                    reminder_message = "Hello, this is a friendly reminder because this is your first time creating a topic (or it has been a while since your last topic) in this category.<br><br>Please note that most of the support is provided by the FiveM community on a voluntary basis. We ask you to be patient; there is no guarantee we have a solution to your problem(s). To avoid unnecessary/duplicate topics, please browse the forums before creating a topic.<br><br>To improve your chances of your issue(s) being solved, please provide as much information as possible about the issue(s) you are having. Also —whenever possible— please use the template given to you when creating a topic.<br><br>Thanks for keeping these forums tidy!<br>:mascot:"
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