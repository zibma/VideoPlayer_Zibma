package com.artxdev.newpipeextractor_dart.youtube;



import org.schabi.newpipe.extractor.InfoItem;
import org.schabi.newpipe.extractor.ListExtractor;
import org.schabi.newpipe.extractor.channel.ChannelInfoItem;
import org.schabi.newpipe.extractor.playlist.PlaylistInfoItem;
import org.schabi.newpipe.extractor.search.SearchExtractor;
import org.schabi.newpipe.extractor.stream.StreamInfoItem;

import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static org.schabi.newpipe.extractor.ServiceList.YouTube;


public class YoutubeSearchExtractor {

    private SearchExtractor extractor;
    private ListExtractor.InfoItemsPage<InfoItem> itemsPage;

    public Map<String, Map<Integer, Map<String, String>>> searchYoutube(String query, List<String> filters) throws Exception {
        extractor = YouTube.getSearchExtractor(query, filters, "");
        extractor.fetchPage();
        itemsPage = extractor.getInitialPage();
        List<InfoItem> items = itemsPage.getItems();
        return _fetchResultsFromItems(items);
    }

    public Map<String, Map<Integer, Map<String, String>>> getNextPage() throws Exception {
        if (itemsPage.hasNextPage()) {
            itemsPage = extractor.getPage(itemsPage.getNextPage());
            List<InfoItem> items = itemsPage.getItems();
            return _fetchResultsFromItems(items);
        } else {
            return new HashMap<>();
        }
    }


   private Map<String, Map<Integer, Map<String, String>>> _fetchResultsFromItems(List<InfoItem> items) {
        List<StreamInfoItem> streamsList = new ArrayList<>();
        List<PlaylistInfoItem> playlistsList = new ArrayList<>();
        List<ChannelInfoItem> channelsList = new ArrayList<>();
        Map<String, Map<Integer, Map<String, String>>> resultsList = new HashMap<>();
        for (int i = 0; i < items.size(); i++) {
            switch (items.get(i).getInfoType()) {
                case STREAM:
                    StreamInfoItem streamInfo = (StreamInfoItem) items.get(i);
                    streamsList.add(streamInfo);
                    break;
                case CHANNEL:
                    ChannelInfoItem channelInfo = (ChannelInfoItem) items.get(i);
                    channelsList.add(channelInfo);
                    break;
                case PLAYLIST:
                    PlaylistInfoItem playlistInfo = (PlaylistInfoItem) items.get(i);
                    playlistsList.add(playlistInfo);
                    break;
                default:
                    break;
            }
        }

        // Extract into a map Stream Results
        Map<Integer, Map<String, String>> streamResultsMap = new HashMap<>();
        if (!streamsList.isEmpty()) {
            for (int i = 0; i < streamsList.size(); i++) {
                Map<String, String> itemMap = new HashMap<>();
                StreamInfoItem item = streamsList.get(i);
                itemMap.put("name", item.getName());
                itemMap.put("uploaderName", item.getUploaderName());
                itemMap.put("uploaderUrl", item.getUploaderUrl());
                itemMap.put("uploadDate", item.getTextualUploadDate());
                try {
                    itemMap.put("date", item.getUploadDate().offsetDateTime().format(DateTimeFormatter.ISO_DATE_TIME));
                } catch (NullPointerException ignore) {
                    itemMap.put("date", null);
                }
                itemMap.put("thumbnailUrl", item.getThumbnailUrl());
                itemMap.put("duration", String.valueOf(item.getDuration()));
                itemMap.put("viewCount", String.valueOf(item.getViewCount()));
                itemMap.put("url", item.getUrl());
                itemMap.put("id", YoutubeLinkHandler.getIdFromStreamUrl(item.getUrl()));
                streamResultsMap.put(i, itemMap);
            }
        }
        resultsList.put("streams", streamResultsMap);

        // Extract into a map Channel Results
       Map<Integer, Map<String, String>> channelResultsMap = new HashMap<>();
        if (!channelsList.isEmpty()) {
            for (int i = 0; i < channelsList.size(); i++) {
                Map<String, String> itemMap = new HashMap<>();
                ChannelInfoItem item = channelsList.get(i);
                itemMap.put("name", item.getName());
                itemMap.put("thumbnailUrl", item.getThumbnailUrl());
                itemMap.put("url", item.getUrl());
                itemMap.put("id", YoutubeLinkHandler.getIdFromChannelUrl(item.getUrl()));
                itemMap.put("description", item.getDescription());
                itemMap.put("streamCount", String.valueOf(item.getStreamCount()));
                itemMap.put("subscriberCount", String.valueOf(item.getSubscriberCount()));
                channelResultsMap.put(i, itemMap);
            }
        }
        resultsList.put("channels", channelResultsMap);

        // Extract into a map Playlist Results
       Map<Integer, Map<String, String>> playlistResultsMap = new HashMap<>();
        if (!playlistsList.isEmpty()) {
            for (int i = 0; i < playlistsList.size(); i++) {
                Map<String, String> itemMap = new HashMap<>();
                PlaylistInfoItem item = playlistsList.get(i);
                itemMap.put("name", item.getName());
                itemMap.put("uploaderName", item.getUploaderName());
                itemMap.put("url", item.getUrl());
                itemMap.put("id", YoutubeLinkHandler.getIdFromPlaylistUrl(item.getUrl()));
                itemMap.put("thumbnailUrl", item.getThumbnailUrl());
                itemMap.put("streamCount", String.valueOf(item.getStreamCount()));
                playlistResultsMap.put(i, itemMap);
            }
        }
        resultsList.put("playlists", playlistResultsMap);
        return resultsList;
    }


}
