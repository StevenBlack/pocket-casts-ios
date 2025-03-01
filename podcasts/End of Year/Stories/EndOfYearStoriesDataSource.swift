import SwiftUI
import PocketCastsDataModel

class EndOfYearStoriesDataSource: StoriesDataSource {
    var numberOfStories: Int {
        stories.count
    }

    var stories: [EndOfYearStory] = []

    var data: EndOfYearStoriesData!

    func story(for storyNumber: Int) -> any StoryView {
        switch stories[storyNumber] {
        case .intro:
            return IntroStory()
        case .listeningTime:
            return ListeningTimeStory(listeningTime: data.listeningTime, podcasts: data.top10Podcasts)
        case .listenedCategories:
            return ListenedCategoriesStory(listenedCategories: data.listenedCategories.reversed())
        case .topCategories:
            return TopListenedCategoriesStory(listenedCategories: data.listenedCategories)
        case .numberOfPodcastsAndEpisodesListened:
            return ListenedNumbersStory(listenedNumbers: data.listenedNumbers, podcasts: data.top10Podcasts)
        case .topOnePodcast:
            return TopOnePodcastStory(topPodcast: data.topPodcasts[0])
        case .topFivePodcasts:
            return TopFivePodcastsStory(podcasts: data.topPodcasts.map { $0.podcast })
        case .longestEpisode:
            return LongestEpisodeStory(episode: data.longestEpisode, podcast: data.longestEpisodePodcast)
        case .epilogue:
            return EpilogueStory()
        }
    }

    /// The only interactive view we have is the last one, with the replay button
    func interactiveView(for storyNumber: Int) -> AnyView {
        switch stories[storyNumber] {
        case .epilogue:
            return AnyView(EpilogueStory())
        default:
            return AnyView(EmptyView())
        }
    }

    func isReady() async -> Bool {
        (stories, data) = await EndOfYearStoriesBuilder().build()

        if !stories.isEmpty {
            stories.insert(.intro, at: 0)
            stories.append(.epilogue)

            return true
        }

        return false
    }
}
