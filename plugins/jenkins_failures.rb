#
# This cinch plugin is part of EV0002
#
# written by carstene1ns <dev @ f4ke . de> 2021-2024
# available under ISC license
#

require 'jenkins2-api'

class Cinch::JenkinsFailures
  include Cinch::Plugin

  # Every hour
  timer 60 * 60, method: :get_failures

  def get_failures
    server = config[:server]
    user = config[:user]
    pass = config[:pass]
    view = config[:view]

    # not found, ignore
    return if server.nil? or user.nil? or pass.nil? or view.nil?

    client = Jenkins2API::Client.new(
      :server   => server,
      :username => user,
      :password => pass
    )

    # get failed jobs, ignoring pull requests
    jobs = client.job.list
    failed = Array.new
    jobs.each do |job|
      if job['color'] == "red" and job['name'] !~ /.*-pr/
        failed.push(job['name'])
      end
    end

    return if failed.empty?

    # filter last hour
    recent = Array.new
    failed.each do |job|
      build = client.build.latest(job)
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
