package com.llamamobile.sdkexample;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;
import androidx.recyclerview.widget.RecyclerView;
import java.util.List;

public class ChatAdapter extends RecyclerView.Adapter<RecyclerView.ViewHolder> {

    private static final int VIEW_TYPE_USER = 1;
    private static final int VIEW_TYPE_ASSISTANT = 2;

    private final List<Message> messages;

    public ChatAdapter(List<Message> messages) {
        this.messages = messages;
    }

    @Override
    public int getItemViewType(int position) {
        String role = messages.get(position).getRole();
        if (Message.ROLE_USER.equals(role)) {
            return VIEW_TYPE_USER;
        } else if (Message.ROLE_ASSISTANT.equals(role)) {
            return VIEW_TYPE_ASSISTANT;
        } else {
            return VIEW_TYPE_ASSISTANT; // Default to assistant
        }
    }

    @Override
    public RecyclerView.ViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {
        LayoutInflater inflater = LayoutInflater.from(parent.getContext());
        switch (viewType) {
            case VIEW_TYPE_USER:
                View userView = inflater.inflate(R.layout.item_message_user, parent, false);
                return new UserMessageViewHolder(userView);
            case VIEW_TYPE_ASSISTANT:
                View assistantView = inflater.inflate(R.layout.item_message_assistant, parent, false);
                return new AssistantMessageViewHolder(assistantView);
            default:
                throw new IllegalArgumentException("Unknown view type: " + viewType);
        }
    }

    @Override
    public void onBindViewHolder(RecyclerView.ViewHolder holder, int position) {
        Message message = messages.get(position);
        if (holder instanceof UserMessageViewHolder) {
            ((UserMessageViewHolder) holder).bind(message);
        } else if (holder instanceof AssistantMessageViewHolder) {
            ((AssistantMessageViewHolder) holder).bind(message);
        }
    }

    @Override
    public int getItemCount() {
        return messages.size();
    }

    // User message view holder
    public static class UserMessageViewHolder extends RecyclerView.ViewHolder {
        private final TextView messageText;
        private final TextView messageSender;

        public UserMessageViewHolder(View itemView) {
            super(itemView);
            messageText = itemView.findViewById(R.id.userMessageText);
            messageSender = itemView.findViewById(R.id.userMessageSender);
        }

        public void bind(Message message) {
            messageText.setText(message.getText());
            messageSender.setText("You");
        }
    }

    // Assistant message view holder
    public static class AssistantMessageViewHolder extends RecyclerView.ViewHolder {
        private final TextView messageText;
        private final TextView messageSender;

        public AssistantMessageViewHolder(View itemView) {
            super(itemView);
            messageText = itemView.findViewById(R.id.assistantMessageText);
            messageSender = itemView.findViewById(R.id.assistantMessageSender);
        }

        public void bind(Message message) {
            messageText.setText(message.getText());
            messageSender.setText("Llama");
        }
    }
}