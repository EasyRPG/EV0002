#
# This cinch plugin is part of EV0002
#
# written by carstene1ns <dev @ f4ke . de> 2021-2026
# available under ISC license
#

require 'jenkins_api_client'

class Cinch::JenkinsFailures
  include Cinch::Plugin

  # Every hour
  timer 60 * 60, method: :get_failures

  # Manual call
  match "jenkins-failures", method: :get_failures_msg
  def get_failures_msg(msg)
    get_failures
  end

  def get_failures
    server = config[:server]
    user = config[:user]
    pass = config[:pass]
    view = config[:view]

    # not found, ignore
    return if server.nil? or user.nil? or pass.nil? or view.nil?

    @client = JenkinsApi::Client.new(
      :server_url => server,
      :username => user,
      :password => pass
    )

    # get failed jobs, ignoring pull requests
    allfailed = @client.job.list_by_status("failure")
    failed = Array.new
    allfailed.each do |job|
      if job !~ /.*-pr/
        failed.push(job)
      end
    end

    return if failed.empty?

    # filter last hour
    recent = Array.new
    failed.each do |job|
      build_num = @client.job.get_current_build_number(job)
      build = @client.job.get_build_details(job, build_num)
      endtime = Time.at((build['timestamp'].to_i + build['duration'].to_i) / 1000)
      recent.push(job) if endtime > Time.now - (60 * 60)
    end

    return if recent.empty?

    shown = recent.join(",")
    message = "New failing jobs (see " + server + "view/" + view + "/ for details): "

    # add up to 200 characters
    message << "\n" + Format(:red, shown[0, 200])
    message << "…" if shown.length > 200

    bot.channels[0].send("[Jenkins] #{message}")
  end
end
