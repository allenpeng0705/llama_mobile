// Vulkan stub implementation for Android build
// This provides minimal implementations of Vulkan functions to satisfy the linker
// The actual Vulkan library will be loaded at runtime by llama.cpp using dlopen()

#include <stdint.h>

// Vulkan error codes
#define VK_SUCCESS 0
#define VK_ERROR_OUT_OF_HOST_MEMORY -1

// Vulkan types (minimal definitions)
typedef uintptr_t VkInstance;
typedef uintptr_t VkPhysicalDevice;
typedef uintptr_t VkDevice;
typedef uintptr_t VkQueue;
typedef uintptr_t VkCommandPool;
typedef uintptr_t VkCommandBuffer;
typedef uintptr_t VkBuffer;
typedef uintptr_t VkImage;
typedef uintptr_t VkImageView;
typedef uintptr_t VkShaderModule;
typedef uintptr_t VkPipelineLayout;
typedef uintptr_t VkPipeline;
typedef uintptr_t VkRenderPass;
typedef uintptr_t VkFramebuffer;
typedef uintptr_t VkSemaphore;
typedef uintptr_t VkFence;
typedef uintptr_t VkDescriptorSetLayout;
typedef uintptr_t VkDescriptorPool;
typedef uintptr_t VkDescriptorSet;
typedef uintptr_t VkSampler;
typedef uintptr_t VkSurfaceKHR;
typedef uintptr_t VkSwapchainKHR;
typedef uintptr_t VkFormat;
typedef uintptr_t VkExtent2D;
typedef uintptr_t VkPhysicalDeviceFeatures;
typedef uintptr_t VkPhysicalDeviceProperties;
typedef uintptr_t VkPhysicalDeviceFeatures2;
typedef uintptr_t VkPhysicalDeviceProperties2;
typedef uintptr_t VkInstanceCreateInfo;
typedef uintptr_t VkDeviceCreateInfo;
typedef uintptr_t VkCommandPoolCreateInfo;
typedef uintptr_t VkCommandBufferAllocateInfo;
typedef uintptr_t VkBufferCreateInfo;
typedef uintptr_t VkMemoryAllocateInfo;
typedef uintptr_t VkImageCreateInfo;
typedef uintptr_t VkImageViewCreateInfo;
typedef uintptr_t VkShaderModuleCreateInfo;
typedef uintptr_t VkPipelineLayoutCreateInfo;
typedef uintptr_t VkGraphicsPipelineCreateInfo;
typedef uintptr_t VkRenderPassCreateInfo;
typedef uintptr_t VkFramebufferCreateInfo;
typedef uintptr_t VkSemaphoreCreateInfo;
typedef uintptr_t VkFenceCreateInfo;
typedef uintptr_t VkDescriptorSetLayoutCreateInfo;
typedef uintptr_t VkDescriptorPoolCreateInfo;
typedef uintptr_t VkDescriptorSetAllocateInfo;
typedef uintptr_t VkSamplerCreateInfo;
typedef uintptr_t VkSwapchainCreateInfoKHR;
typedef uintptr_t VkCommandBufferBeginInfo;
typedef uintptr_t VkSubmitInfo;
typedef uintptr_t VkPresentInfoKHR;
typedef uintptr_t VkClearColorValue;
typedef uintptr_t VkClearDepthStencilValue;
typedef uintptr_t VkClearValue;
typedef uintptr_t VkRect2D;
typedef uintptr_t VkViewport;
typedef uintptr_t VkDeviceSize;
typedef uintptr_t VkQueueFlags;
typedef uintptr_t VkMemoryPropertyFlags;
typedef uintptr_t VkBufferUsageFlags;
typedef uintptr_t VkImageUsageFlags;
typedef uintptr_t VkShaderStageFlags;
typedef uintptr_t VkAccessFlags;
typedef uintptr_t VkPipelineStageFlags;
typedef uintptr_t VkDependencyFlags;
typedef uintptr_t VkDescriptorType;
typedef uintptr_t VkSamplerAddressMode;
typedef uintptr_t VkFilter;
typedef uintptr_t VkColorSpaceKHR;
typedef uintptr_t VkPresentModeKHR;
typedef uintptr_t VkSurfaceFormatKHR;
typedef uintptr_t VkSwapchainKHR;
typedef uintptr_t VkResult;
typedef uintptr_t VkBool32;
typedef uintptr_t VkFlags;
typedef uintptr_t VkDeviceSize;
typedef uintptr_t VkSampleCountFlagBits;
typedef uintptr_t VkAllocationCallbacks;
typedef uintptr_t VkExtensionProperties;
typedef uintptr_t VkQueueFamilyProperties;

// Function prototypes for Vulkan functions referenced by llama.cpp
VkResult vkEnumerateInstanceVersion(uint32_t* pApiVersion);
VkResult vkGetPhysicalDeviceFeatures2(VkPhysicalDevice physicalDevice, VkPhysicalDeviceFeatures2* pFeatures);
VkResult vkGetPhysicalDeviceProperties2(VkPhysicalDevice physicalDevice, VkPhysicalDeviceProperties2* pProperties);
VkResult vkEnumerateInstanceExtensionProperties(const char* pLayerName, uint32_t* pPropertyCount, VkExtensionProperties* pProperties);
VkResult vkCreateInstance(const VkInstanceCreateInfo* pCreateInfo, const VkAllocationCallbacks* pAllocator, VkInstance* pInstance);
VkResult vkEnumerateDeviceExtensionProperties(VkPhysicalDevice physicalDevice, const char* pLayerName, uint32_t* pPropertyCount, VkExtensionProperties* pProperties);
VkResult vkGetPhysicalDeviceFeatures(VkPhysicalDevice physicalDevice, VkPhysicalDeviceFeatures* pFeatures);
VkResult vkDestroyFence(VkDevice device, VkFence fence, const VkAllocationCallbacks* pAllocator);
VkResult vkDestroyCommandPool(VkDevice device, VkCommandPool commandPool, const VkAllocationCallbacks* pAllocator);
VkResult vkDestroyDescriptorPool(VkDevice device, VkDescriptorPool descriptorPool, const VkAllocationCallbacks* pAllocator);
VkResult vkDestroyDescriptorSetLayout(VkDevice device, VkDescriptorSetLayout descriptorSetLayout, const VkAllocationCallbacks* pAllocator);
VkResult vkDestroyPipelineLayout(VkDevice device, VkPipelineLayout pipelineLayout, const VkAllocationCallbacks* pAllocator);
VkResult vkDestroyShaderModule(VkDevice device, VkShaderModule shaderModule, const VkAllocationCallbacks* pAllocator);
VkResult vkDestroyPipeline(VkDevice device, VkPipeline pipeline, const VkAllocationCallbacks* pAllocator);
VkResult vkDestroyDevice(VkDevice device, const VkAllocationCallbacks* pAllocator);
VkResult vkGetPhysicalDeviceQueueFamilyProperties(VkPhysicalDevice physicalDevice, uint32_t* pQueueFamilyPropertyCount, VkQueueFamilyProperties* pQueueFamilyProperties);
VkResult vkCreateDevice(VkPhysicalDevice physicalDevice, const VkDeviceCreateInfo* pCreateInfo, const VkAllocationCallbacks* pAllocator, VkDevice* pDevice);
VkResult vkCreateCommandPool(VkDevice device, const VkCommandPoolCreateInfo* pCreateInfo, const VkAllocationCallbacks* pAllocator, VkCommandPool* pCommandPool);
VkResult vkGetDeviceQueue(VkDevice device, uint32_t queueFamilyIndex, uint32_t queueIndex, VkQueue* pQueue);
VkResult vkCreateShaderModule(VkDevice device, const VkShaderModuleCreateInfo* pCreateInfo, const VkAllocationCallbacks* pAllocator, VkShaderModule* pShaderModule);
VkResult vkCreateDescriptorSetLayout(VkDevice device, const VkDescriptorSetLayoutCreateInfo* pCreateInfo, const VkAllocationCallbacks* pAllocator, VkDescriptorSetLayout* pSetLayout);
VkResult vkCreateDescriptorPool(VkDevice device, const VkDescriptorPoolCreateInfo* pCreateInfo, const VkAllocationCallbacks* pAllocator, VkDescriptorPool* pDescriptorPool);
VkResult vkCreateBuffer(VkDevice device, const VkBufferCreateInfo* pCreateInfo, const VkAllocationCallbacks* pAllocator, VkBuffer* pBuffer);
VkResult vkGetBufferMemoryRequirements(VkDevice device, VkBuffer buffer, void* pMemoryRequirements);
VkResult vkDestroyBuffer(VkDevice device, VkBuffer buffer, const VkAllocationCallbacks* pAllocator);
VkResult vkAllocateMemory(VkDevice device, const void* pAllocateInfo, const VkAllocationCallbacks* pAllocator, void* pMemory);
VkResult vkMapMemory(VkDevice device, void* memory, uint64_t offset, uint64_t size, uint32_t flags, void** ppData);
VkResult vkBindBufferMemory(VkDevice device, VkBuffer buffer, void* memory, uint64_t memoryOffset);
VkResult vkAllocateCommandBuffers(VkDevice device, const void* pAllocateInfo, VkCommandBuffer* pCommandBuffers);
VkResult vkBeginCommandBuffer(VkCommandBuffer commandBuffer, const void* pBeginInfo);
VkResult vkCmdFillBuffer(VkCommandBuffer commandBuffer, VkBuffer dstBuffer, uint64_t dstOffset, uint64_t size, uint32_t data);
VkResult vkEndCommandBuffer(VkCommandBuffer commandBuffer);
VkResult vkQueueSubmit(VkQueue queue, uint32_t submitCount, const void* pSubmits, VkFence fence);
VkResult vkWaitForFences(VkDevice device, uint32_t fenceCount, const VkFence* pFences, VkBool32 waitAll, uint64_t timeout);
VkResult vkResetFences(VkDevice device, uint32_t fenceCount, const VkFence* pFences);
VkResult vkCmdCopyBuffer(VkCommandBuffer commandBuffer, VkBuffer srcBuffer, VkBuffer dstBuffer, uint32_t regionCount, const void* pRegions);
VkResult vkCmdPipelineBarrier(VkCommandBuffer commandBuffer, uint32_t srcStageMask, uint32_t dstStageMask, uint32_t dependencyFlags, uint32_t memoryBarrierCount, const void* pMemoryBarriers, uint32_t bufferMemoryBarrierCount, const void* pBufferMemoryBarriers, uint32_t imageMemoryBarrierCount, const void* pImageMemoryBarriers);
VkResult vkCreateFence(VkDevice device, const void* pCreateInfo, const VkAllocationCallbacks* pAllocator, VkFence* pFence);
VkResult vkGetInstanceProcAddr(VkInstance instance, const char* pName);
VkResult vkCreatePipelineLayout(VkDevice device, const void* pCreateInfo, const VkAllocationCallbacks* pAllocator, VkPipelineLayout* pPipelineLayout);
VkResult vkCreateComputePipelines(VkDevice device, void* pipelineCache, uint32_t createInfoCount, const void* pCreateInfos, const VkAllocationCallbacks* pAllocator, VkPipeline* pPipelines);
VkResult vkFreeMemory(VkDevice device, void* memory, const VkAllocationCallbacks* pAllocator);
VkResult vkResetCommandPool(VkDevice device, VkCommandPool commandPool, uint32_t flags);
VkResult vkDestroySemaphore(VkDevice device, void* semaphore, const VkAllocationCallbacks* pAllocator);
VkResult vkResetEvent(VkDevice device, void* event);
VkResult vkDestroyEvent(VkDevice device, void* event, const VkAllocationCallbacks* pAllocator);
VkResult vkUpdateDescriptorSets(VkDevice device, uint32_t descriptorWriteCount, const void* pDescriptorWrites, uint32_t descriptorCopyCount, const void* pDescriptorCopies);
VkResult vkCmdPushConstants(VkCommandBuffer commandBuffer, VkPipelineLayout layout, uint32_t stageFlags, uint32_t offset, uint32_t size, const void* pValues);
VkResult vkCmdBindPipeline(VkCommandBuffer commandBuffer, uint32_t pipelineBindPoint, VkPipeline pipeline);
VkResult vkCmdBindDescriptorSets(VkCommandBuffer commandBuffer, uint32_t pipelineBindPoint, VkPipelineLayout layout, uint32_t firstSet, uint32_t descriptorSetCount, const void* pDescriptorSets, uint32_t dynamicOffsetCount, const uint32_t* pDynamicOffsets);
VkResult vkCmdDispatch(VkCommandBuffer commandBuffer, uint32_t groupCountX, uint32_t groupCountY, uint32_t groupCountZ);
VkResult vkAllocateDescriptorSets(VkDevice device, const void* pAllocateInfo, void* pDescriptorSets);
VkResult vkGetPhysicalDeviceProperties(VkPhysicalDevice physicalDevice, void* pProperties);
VkResult vkGetPhysicalDeviceMemoryProperties(VkPhysicalDevice physicalDevice, void* pMemoryProperties);
VkResult vkEnumeratePhysicalDevices(VkInstance instance, uint32_t* pPhysicalDeviceCount, VkPhysicalDevice* pPhysicalDevices);

// Minimal implementations that return error codes
VkResult vkEnumerateInstanceVersion(uint32_t* pApiVersion) {
    if (pApiVersion) *pApiVersion = 0;
    return VK_ERROR_OUT_OF_HOST_MEMORY;
}

VkResult vkGetPhysicalDeviceFeatures2(VkPhysicalDevice physicalDevice, VkPhysicalDeviceFeatures2* pFeatures) {
    return VK_ERROR_OUT_OF_HOST_MEMORY;
}

VkResult vkGetPhysicalDeviceProperties2(VkPhysicalDevice physicalDevice, VkPhysicalDeviceProperties2* pProperties) {
    return VK_ERROR_OUT_OF_HOST_MEMORY;
}

VkResult vkEnumerateInstanceExtensionProperties(const char* pLayerName, uint32_t* pPropertyCount, VkExtensionProperties* pProperties) {
    if (pPropertyCount) *pPropertyCount = 0;
    return VK_ERROR_OUT_OF_HOST_MEMORY;
}

VkResult vkCreateInstance(const VkInstanceCreateInfo* pCreateInfo, const VkAllocationCallbacks* pAllocator, VkInstance* pInstance) {
    if (pInstance) *pInstance = 0;
    return VK_ERROR_OUT_OF_HOST_MEMORY;
}

VkResult vkEnumerateDeviceExtensionProperties(VkPhysicalDevice physicalDevice, const char* pLayerName, uint32_t* pPropertyCount, VkExtensionProperties* pProperties) {
    if (pPropertyCount) *pPropertyCount = 0;
    return VK_ERROR_OUT_OF_HOST_MEMORY;
}

VkResult vkGetPhysicalDeviceFeatures(VkPhysicalDevice physicalDevice, VkPhysicalDeviceFeatures* pFeatures) {
    return VK_ERROR_OUT_OF_HOST_MEMORY;
}

VkResult vkDestroyFence(VkDevice device, VkFence fence, const VkAllocationCallbacks* pAllocator) {
    return VK_ERROR_OUT_OF_HOST_MEMORY;
}

VkResult vkDestroyCommandPool(VkDevice device, VkCommandPool commandPool, const VkAllocationCallbacks* pAllocator) {
    return VK_ERROR_OUT_OF_HOST_MEMORY;
}

VkResult vkDestroyDescriptorPool(VkDevice device, VkDescriptorPool descriptorPool, const VkAllocationCallbacks* pAllocator) {
    return VK_ERROR_OUT_OF_HOST_MEMORY;
}

VkResult vkDestroyDescriptorSetLayout(VkDevice device, VkDescriptorSetLayout descriptorSetLayout, const VkAllocationCallbacks* pAllocator) {
    return VK_ERROR_OUT_OF_HOST_MEMORY;
}

VkResult vkDestroyPipelineLayout(VkDevice device, VkPipelineLayout pipelineLayout, const VkAllocationCallbacks* pAllocator) {
    return VK_ERROR_OUT_OF_HOST_MEMORY;
}

VkResult vkDestroyShaderModule(VkDevice device, VkShaderModule shaderModule, const VkAllocationCallbacks* pAllocator) {
    return VK_ERROR_OUT_OF_HOST_MEMORY;
}

VkResult vkDestroyPipeline(VkDevice device, VkPipeline pipeline, const VkAllocationCallbacks* pAllocator) {
    return VK_ERROR_OUT_OF_HOST_MEMORY;
}

VkResult vkDestroyDevice(VkDevice device, const VkAllocationCallbacks* pAllocator) {
    return VK_ERROR_OUT_OF_HOST_MEMORY;
}

VkResult vkGetPhysicalDeviceQueueFamilyProperties(VkPhysicalDevice physicalDevice, uint32_t* pQueueFamilyPropertyCount, VkQueueFamilyProperties* pQueueFamilyProperties) {
    if (pQueueFamilyPropertyCount) *pQueueFamilyPropertyCount = 0;
    return VK_ERROR_OUT_OF_HOST_MEMORY;
}

VkResult vkCreateDevice(VkPhysicalDevice physicalDevice, const VkDeviceCreateInfo* pCreateInfo, const VkAllocationCallbacks* pAllocator, VkDevice* pDevice) {
    if (pDevice) *pDevice = 0;
    return VK_ERROR_OUT_OF_HOST_MEMORY;
}

VkResult vkCreateCommandPool(VkDevice device, const VkCommandPoolCreateInfo* pCreateInfo, const VkAllocationCallbacks* pAllocator, VkCommandPool* pCommandPool) {
    if (pCommandPool) *pCommandPool = 0;
    return VK_ERROR_OUT_OF_HOST_MEMORY;
}

VkResult vkGetDeviceQueue(VkDevice device, uint32_t queueFamilyIndex, uint32_t queueIndex, VkQueue* pQueue) {
    if (pQueue) *pQueue = 0;
    return VK_ERROR_OUT_OF_HOST_MEMORY;
}

VkResult vkCreateShaderModule(VkDevice device, const VkShaderModuleCreateInfo* pCreateInfo, const VkAllocationCallbacks* pAllocator, VkShaderModule* pShaderModule) {
    if (pShaderModule) *pShaderModule = 0;
    return VK_ERROR_OUT_OF_HOST_MEMORY;
}

VkResult vkCreateDescriptorSetLayout(VkDevice device, const VkDescriptorSetLayoutCreateInfo* pCreateInfo, const VkAllocationCallbacks* pAllocator, VkDescriptorSetLayout* pSetLayout) {
    if (pSetLayout) *pSetLayout = 0;
    return VK_ERROR_OUT_OF_HOST_MEMORY;
}

VkResult vkCreateDescriptorPool(VkDevice device, const VkDescriptorPoolCreateInfo* pCreateInfo, const VkAllocationCallbacks* pAllocator, VkDescriptorPool* pDescriptorPool) {
    if (pDescriptorPool) *pDescriptorPool = 0;
    return VK_ERROR_OUT_OF_HOST_MEMORY;
}

VkResult vkCreateBuffer(VkDevice device, const VkBufferCreateInfo* pCreateInfo, const VkAllocationCallbacks* pAllocator, VkBuffer* pBuffer) {
    if (pBuffer) *pBuffer = 0;
    return VK_ERROR_OUT_OF_HOST_MEMORY;
}

VkResult vkGetBufferMemoryRequirements(VkDevice device, VkBuffer buffer, void* pMemoryRequirements) {
    return VK_ERROR_OUT_OF_HOST_MEMORY;
}

VkResult vkDestroyBuffer(VkDevice device, VkBuffer buffer, const VkAllocationCallbacks* pAllocator) {
    return VK_ERROR_OUT_OF_HOST_MEMORY;
}

VkResult vkAllocateMemory(VkDevice device, const void* pAllocateInfo, const VkAllocationCallbacks* pAllocator, void* pMemory) {
    if (pMemory) *(void**)pMemory = 0;
    return VK_ERROR_OUT_OF_HOST_MEMORY;
}

VkResult vkMapMemory(VkDevice device, void* memory, uint64_t offset, uint64_t size, uint32_t flags, void** ppData) {
    if (ppData) *ppData = 0;
    return VK_ERROR_OUT_OF_HOST_MEMORY;
}

VkResult vkBindBufferMemory(VkDevice device, VkBuffer buffer, void* memory, uint64_t memoryOffset) {
    return VK_ERROR_OUT_OF_HOST_MEMORY;
}

VkResult vkAllocateCommandBuffers(VkDevice device, const void* pAllocateInfo, VkCommandBuffer* pCommandBuffers) {
    if (pCommandBuffers) *pCommandBuffers = 0;
    return VK_ERROR_OUT_OF_HOST_MEMORY;
}

VkResult vkBeginCommandBuffer(VkCommandBuffer commandBuffer, const void* pBeginInfo) {
    return VK_ERROR_OUT_OF_HOST_MEMORY;
}

VkResult vkCmdFillBuffer(VkCommandBuffer commandBuffer, VkBuffer dstBuffer, uint64_t dstOffset, uint64_t size, uint32_t data) {
    return VK_ERROR_OUT_OF_HOST_MEMORY;
}

VkResult vkEndCommandBuffer(VkCommandBuffer commandBuffer) {
    return VK_ERROR_OUT_OF_HOST_MEMORY;
}

VkResult vkQueueSubmit(VkQueue queue, uint32_t submitCount, const void* pSubmits, VkFence fence) {
    return VK_ERROR_OUT_OF_HOST_MEMORY;
}

VkResult vkWaitForFences(VkDevice device, uint32_t fenceCount, const VkFence* pFences, VkBool32 waitAll, uint64_t timeout) {
    return VK_ERROR_OUT_OF_HOST_MEMORY;
}

VkResult vkResetFences(VkDevice device, uint32_t fenceCount, const VkFence* pFences) {
    return VK_ERROR_OUT_OF_HOST_MEMORY;
}

VkResult vkCmdCopyBuffer(VkCommandBuffer commandBuffer, VkBuffer srcBuffer, VkBuffer dstBuffer, uint32_t regionCount, const void* pRegions) {
    return VK_ERROR_OUT_OF_HOST_MEMORY;
}

VkResult vkCmdPipelineBarrier(VkCommandBuffer commandBuffer, uint32_t srcStageMask, uint32_t dstStageMask, uint32_t dependencyFlags, uint32_t memoryBarrierCount, const void* pMemoryBarriers, uint32_t bufferMemoryBarrierCount, const void* pBufferMemoryBarriers, uint32_t imageMemoryBarrierCount, const void* pImageMemoryBarriers) {
    return VK_ERROR_OUT_OF_HOST_MEMORY;
}

VkResult vkCreateFence(VkDevice device, const void* pCreateInfo, const VkAllocationCallbacks* pAllocator, VkFence* pFence) {
    if (pFence) *pFence = 0;
    return VK_ERROR_OUT_OF_HOST_MEMORY;
}

VkResult vkGetInstanceProcAddr(VkInstance instance, const char* pName) {
    return (VkResult)0;
}

VkResult vkCreatePipelineLayout(VkDevice device, const void* pCreateInfo, const VkAllocationCallbacks* pAllocator, VkPipelineLayout* pPipelineLayout) {
    if (pPipelineLayout) *pPipelineLayout = 0;
    return VK_ERROR_OUT_OF_HOST_MEMORY;
}

VkResult vkCreateComputePipelines(VkDevice device, void* pipelineCache, uint32_t createInfoCount, const void* pCreateInfos, const VkAllocationCallbacks* pAllocator, VkPipeline* pPipelines) {
    if (pPipelines) *pPipelines = 0;
    return VK_ERROR_OUT_OF_HOST_MEMORY;
}

VkResult vkFreeMemory(VkDevice device, void* memory, const VkAllocationCallbacks* pAllocator) {
    return VK_ERROR_OUT_OF_HOST_MEMORY;
}

VkResult vkResetCommandPool(VkDevice device, VkCommandPool commandPool, uint32_t flags) {
    return VK_ERROR_OUT_OF_HOST_MEMORY;
}

VkResult vkDestroySemaphore(VkDevice device, void* semaphore, const VkAllocationCallbacks* pAllocator) {
    return VK_ERROR_OUT_OF_HOST_MEMORY;
}

VkResult vkResetEvent(VkDevice device, void* event) {
    return VK_ERROR_OUT_OF_HOST_MEMORY;
}

VkResult vkDestroyEvent(VkDevice device, void* event, const VkAllocationCallbacks* pAllocator) {
    return VK_ERROR_OUT_OF_HOST_MEMORY;
}

VkResult vkUpdateDescriptorSets(VkDevice device, uint32_t descriptorWriteCount, const void* pDescriptorWrites, uint32_t descriptorCopyCount, const void* pDescriptorCopies) {
    return VK_ERROR_OUT_OF_HOST_MEMORY;
}

VkResult vkCmdPushConstants(VkCommandBuffer commandBuffer, VkPipelineLayout layout, uint32_t stageFlags, uint32_t offset, uint32_t size, const void* pValues) {
    return VK_ERROR_OUT_OF_HOST_MEMORY;
}

VkResult vkCmdBindPipeline(VkCommandBuffer commandBuffer, uint32_t pipelineBindPoint, VkPipeline pipeline) {
    return VK_ERROR_OUT_OF_HOST_MEMORY;
}

VkResult vkCmdBindDescriptorSets(VkCommandBuffer commandBuffer, uint32_t pipelineBindPoint, VkPipelineLayout layout, uint32_t firstSet, uint32_t descriptorSetCount, const void* pDescriptorSets, uint32_t dynamicOffsetCount, const uint32_t* pDynamicOffsets) {
    return VK_ERROR_OUT_OF_HOST_MEMORY;
}

VkResult vkCmdDispatch(VkCommandBuffer commandBuffer, uint32_t groupCountX, uint32_t groupCountY, uint32_t groupCountZ) {
    return VK_ERROR_OUT_OF_HOST_MEMORY;
}

VkResult vkAllocateDescriptorSets(VkDevice device, const void* pAllocateInfo, void* pDescriptorSets) {
    if (pDescriptorSets) *(void**)pDescriptorSets = 0;
    return VK_ERROR_OUT_OF_HOST_MEMORY;
}

VkResult vkGetPhysicalDeviceProperties(VkPhysicalDevice physicalDevice, void* pProperties) {
    return VK_ERROR_OUT_OF_HOST_MEMORY;
}

VkResult vkGetPhysicalDeviceMemoryProperties(VkPhysicalDevice physicalDevice, void* pMemoryProperties) {
    return VK_ERROR_OUT_OF_HOST_MEMORY;
}

VkResult vkEnumeratePhysicalDevices(VkInstance instance, uint32_t* pPhysicalDeviceCount, VkPhysicalDevice* pPhysicalDevices) {
    if (pPhysicalDeviceCount) *pPhysicalDeviceCount = 0;
    return VK_ERROR_OUT_OF_HOST_MEMORY;
}
