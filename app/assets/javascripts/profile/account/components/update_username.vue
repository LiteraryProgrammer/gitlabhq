<script>
import { escape } from 'lodash';
import { GlSafeHtmlDirective as SafeHtml, GlButton, GlModal, GlModalDirective } from '@gitlab/ui';
import axios from '~/lib/utils/axios_utils';
import { s__, sprintf } from '~/locale';
import { deprecatedCreateFlash as Flash } from '~/flash';

export default {
  components: {
    GlModal,
    GlButton,
  },
  directives: {
    GlModalDirective,
    SafeHtml,
  },
  props: {
    actionUrl: {
      type: String,
      required: true,
    },
    rootUrl: {
      type: String,
      required: true,
    },
    initialUsername: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      isRequestPending: false,
      username: this.initialUsername,
      newUsername: this.initialUsername,
    };
  },
  computed: {
    path() {
      return sprintf(s__('Profiles|Current path: %{path}'), {
        path: `${this.rootUrl}${this.username}`,
      });
    },
    modalText() {
      return sprintf(
        s__(`Profiles|
You are going to change the username %{currentUsernameBold} to %{newUsernameBold}.
Profile and projects will be redirected to the %{newUsername} namespace but this redirect will expire once the %{currentUsername} namespace is registered by another user or group.
Please update your Git repository remotes as soon as possible.`),
        {
          currentUsernameBold: `<strong>${escape(this.username)}</strong>`,
          newUsernameBold: `<strong>${escape(this.newUsername)}</strong>`,
          currentUsername: escape(this.username),
          newUsername: escape(this.newUsername),
        },
        false,
      );
    },
    primaryProps() {
      return {
        text: s__('Update username'),
        attributes: [
          { variant: 'warning' },
          { category: 'primary' },
          { disabled: this.isRequestPending },
        ],
      };
    },
    cancelProps() {
      return {
        text: s__('Cancel'),
      };
    },
  },
  methods: {
    onConfirm() {
      this.isRequestPending = true;
      const username = this.newUsername;
      const putData = {
        user: {
          username,
        },
      };

      return axios
        .put(this.actionUrl, putData)
        .then(result => {
          Flash(result.data.message, 'notice');
          this.username = username;
          this.isRequestPending = false;
        })
        .catch(error => {
          Flash(error.response.data.message);
          this.isRequestPending = false;
          throw error;
        });
    },
  },
  modalId: 'username-change-confirmation-modal',
  inputId: 'username-change-input',
  buttonText: s__('Profiles|Update username'),
};
</script>
<template>
  <div>
    <div class="form-group">
      <label :for="$options.inputId">{{ s__('Profiles|Path') }}</label>
      <div class="input-group">
        <div class="input-group-prepend">
          <div class="input-group-text">{{ rootUrl }}</div>
        </div>
        <input
          :id="$options.inputId"
          v-model="newUsername"
          :disabled="isRequestPending"
          class="form-control"
          required="required"
        />
      </div>
      <p class="form-text text-muted">{{ path }}</p>
    </div>
    <gl-button
      v-gl-modal-directive="$options.modalId"
      :disabled="isRequestPending || newUsername === username"
      category="primary"
      variant="warning"
      data-testid="username-change-confirmation-modal"
      >{{ $options.buttonText }}</gl-button
    >
    <gl-modal
      :modal-id="$options.modalId"
      :title="s__('Profiles|Change username') + '?'"
      :action-primary="primaryProps"
      :action-cancel="cancelProps"
      @primary="onConfirm"
    >
      <span v-safe-html="modalText"></span>
    </gl-modal>
  </div>
</template>
