// ----------------------------------------------------------------
// Gunrock -- Fast and Efficient GPU Graph Library
// ----------------------------------------------------------------
// This source code is distributed under the terms of LICENSE.TXT
// in the root directory of this source distribution.
// ----------------------------------------------------------------

/**
 * @file
 * kernel.cuh
 *
 * @brief Filter Kernel
 */

//TODO: Add d_visit_lookup and d_valid_in d_valid_out into ProblemBase

#pragma once
#include <cub/cub.cuh>

#include <gunrock/util/cta_work_distribution.cuh>
#include <gunrock/util/cta_work_progress.cuh>
#include <gunrock/util/kernel_runtime_stats.cuh>
#include <gunrock/util/device_intrinsics.cuh>

#include <gunrock/oprtr/filter/cta.cuh>
#include <gunrock/oprtr/filter/kernel_policy.cuh>

namespace gunrock {
namespace oprtr {
namespace filter {

/**
 * @brief Structure for invoking CTA processing tile over all elements.
 *
 * @tparam KernelPolicy Kernel policy type for partitioned edge mapping.
 * @tparam Problem Problem data type for partitioned edge mapping.
 * @tparam Functor Functor type for the specific problem type.
 */
template <typename KernelPolicy, typename Problem, typename Functor>
struct SweepPass
{
    typedef Cta<KernelPolicy, Problem, Functor>         Cta;
    typedef typename KernelPolicy::SizeT                SizeT;
    typedef typename KernelPolicy::VertexId             VertexId;
    typedef typename KernelPolicy::Value                Value;

    static __device__ __forceinline__ void Invoke(
        //VertexId         &iteration,
        typename Functor::LabelT &label,
        VertexId         &queue_index,
        //int                                     &num_gpus,
        VertexId         *&d_in,
        Value            *&d_value_in,
        VertexId         *&d_out,
        typename Problem::DataSlice        *&d_data_slice,
        unsigned char                      *&d_visited_mask,
        typename KernelPolicy::SmemStorage  &smem_storage,
        util::CtaWorkProgress    <SizeT>    &work_progress,
        util::CtaWorkDistribution<SizeT>    &work_decomposition,
        SizeT            &max_out_frontier)
        //texture<unsigned char, cudaTextureType1D, cudaReadModeElementType> *&t_bitmask)
    {

        // Determine our threadblock's work range
        util::CtaWorkLimits<SizeT> work_limits;
        work_decomposition.template GetCtaWorkLimits<
            KernelPolicy::LOG_TILE_ELEMENTS,
            KernelPolicy::LOG_SCHEDULE_GRANULARITY>(work_limits);

        // Return if we have no work to do
        if (!work_limits.elements) {
            return;
        }

        // CTA processing abstraction
        Cta cta(
            //iteration,
            label,
            queue_index,
            //num_gpus,
            smem_storage,
            d_in,
            d_value_in,
            d_out,
            d_data_slice,
            d_visited_mask,
            work_progress,
            max_out_frontier);
	    //t_bitmask);

        // Process full tiles
        while (work_limits.offset < work_limits.guarded_offset) {

            cta.ProcessTile(work_limits.offset);
            work_limits.offset += KernelPolicy::TILE_ELEMENTS;
        }

        // Clean up last partial tile with guarded-i/o
        if (work_limits.guarded_elements) {
            cta.ProcessTile(
                work_limits.offset,
                work_limits.guarded_elements);
        }
    }
};

/******************************************************************************
 * Arch dispatch
 ******************************************************************************/

/**
 * Not valid for this arch (default)
 *
 * @tparam KernelPolicy Kernel policy type for partitioned edge mapping.
 * @tparam Problem Problem data type for partitioned edge mapping.
 * @tparam Functor Functor type for the specific problem type.
 * @tparam VALID.
 */
template <
    typename    KernelPolicy,
    typename    Problem,
    typename    Functor,
    bool        VALID = (__GR_CUDA_ARCH__ >= KernelPolicy::CUDA_ARCH)>
struct Dispatch
{
    typedef typename KernelPolicy::VertexId VertexId;
    typedef typename KernelPolicy::SizeT    SizeT;
    typedef typename KernelPolicy::Value    Value;
    typedef typename Problem::DataSlice     DataSlice;
    typedef typename Functor::LabelT        LabelT;

    static __device__ __forceinline__ void MarkVisit(
                VertexId *&vertex_in,
                SizeT *&visit_lookup,
                SizeT &input_queue_length,
                SizeT &node_num)
    {
        // Empty
    }

    static __device__ __forceinline__ void MarkValid(
                VertexId *&vertex_in,
                SizeT *&visit_lookup,
                VertexId *&valid_in,
                SizeT &input_queue_length,
                SizeT &node_num)
    {
        // Empty
    }

    static __device__ __forceinline__ void Compact(
                VertexId *&vertex_in,
                VertexId *&vertex_out,
                VertexId *&valid_out,
                LabelT    label,
                DataSlice *&data_slice,
                SizeT &input_queue_length,
                SizeT &node_num)
    {
        // Empty
    }

    static __device__ __forceinline__ void Filter(
            VertexId &iteration,
            bool &queue_reset,
            VertexId &queue_index,
            //int &num_gpus,
            SizeT &num_elements,
            //volatile int *&d_done,
            VertexId  *&d_in_queue,
            VertexId  *&d_out_queue,
            DataSlice *&d_data_slice,
            util::CtaWorkProgress<SizeT> &work_progress,
            SizeT &max_in_queue,
            SizeT &max_out_queue,
            util::KernelRuntimeStats &kernel_stats)
    {
        //Empty
    }

    static __device__ __forceinline__ void  Kernel2(
            //VertexId &iteration,
            LabelT label,
            bool &queue_reset,
            VertexId &queue_index,
            //int &num_gpus,
            SizeT &num_elements,
            //volatile int *&d_done,
            VertexId  *&d_in_queue,
            VertexId  *&d_out_queue,
            DataSlice *&d_data_slice,
            util::CtaWorkProgress<SizeT> &work_progress,
            SizeT &max_in_queue,
            SizeT &max_out_queue,
            util::KernelRuntimeStats &kernel_stats)
    {
      //Empty
    }

    static __device__ __forceinline__ void Kernel(
        //VertexId                    &iteration,
        LabelT                      &label,
        bool                        &queue_reset,
        VertexId                    &queue_index,
        //int                         &num_gpus,
        SizeT                       &num_elements,
        //volatile int                *&d_done,
        VertexId                    *&d_in,
        Value                       *&d_value_in,
        VertexId                    *&d_out,
        DataSlice                   *&d_data_slice,
        unsigned char               *&d_visited_mask,
        util::CtaWorkProgress<SizeT> &work_progress,
        SizeT                       &max_in_frontier,
        SizeT                       &max_out_frontier,
        util::KernelRuntimeStats    &kernel_stats)
        //texture<unsigned char, cudaTextureType1D, cudaReadModeElementType> *&ts_bitmask)
    {
        // empty
    }
};


/**
 * @brief Kernel dispatch code for different architectures.
 *
 * @tparam KernelPolicy Kernel policy type for partitioned edge mapping.
 * @tparam Problem Problem data type for partitioned edge mapping.
 * @tparam Functor Functor type for the specific problem type.
 */
template <typename KernelPolicy, typename Problem, typename Functor>
struct Dispatch<KernelPolicy, Problem, Functor, true>
{
    typedef typename KernelPolicy::VertexId VertexId;
    typedef typename KernelPolicy::SizeT    SizeT;
    typedef typename KernelPolicy::Value    Value;
    typedef typename Problem::DataSlice     DataSlice;
    typedef typename Functor::LabelT        LabelT;

    static __device__ __forceinline__ void Kernel(
        //VertexId                    &iteration,
        LabelT                      &label,
        bool                        &queue_reset,
        VertexId                    &queue_index,
        SizeT                       &num_elements,
        VertexId                    *&d_in,
        Value                       *&d_value_in,
        VertexId                    *&d_out,
        DataSlice                   *&d_data_slice,
        unsigned char               *&d_visited_mask,
        util::CtaWorkProgress<SizeT> &work_progress,
        SizeT                       &max_in_frontier,
        SizeT                       &max_out_frontier,
        util::KernelRuntimeStats    &kernel_stats)
        //texture<unsigned char, cudaTextureType1D, cudaReadModeElementType> *&t_bitmask)
    {

        // Shared storage for the kernel
        __shared__ typename KernelPolicy::SmemStorage smem_storage;

        //if (KernelPolicy::INSTRUMENT && (threadIdx.x == 0)) {
        //    kernel_stats.MarkStart();
        //}

        // workprogress reset
        //if (queue_reset)
        //{
        //    if (threadIdx.x < gunrock::util::CtaWorkProgress::COUNTERS) {
                //Reset all counters
        //        work_progress.template Reset<SizeT>();
        //    }
        //}


        // Determine work decomposition
        if (threadIdx.x == 0) {
            // Obtain problem size
            if (queue_reset)
            {
                work_progress.StoreQueueLength(num_elements, queue_index);
            }
            else
            {
                num_elements = work_progress.LoadQueueLength(queue_index);

                // Check if we previously overflowed
                if (num_elements >= max_in_frontier) {
                    //printf(" num_elements >= max_in_frontier, num_elements = %d, max_in_frontier = %d\n", num_elements, max_in_frontier);
                    num_elements = 0;
                }

                // Signal to host that we're done
                //if ((num_elements == 0) ||
                //        (KernelPolicy::SATURATION_QUIT && (num_elements <= gridDim.x * KernelPolicy::SATURATION_QUIT)))
                //{
                //    if (d_done) d_done[0] = num_elements;
                //}
            }

            // Initialize work decomposition in smem
            smem_storage.state.work_decomposition.template Init<KernelPolicy::LOG_SCHEDULE_GRANULARITY>(
                    num_elements, gridDim.x);

            // Reset our next outgoing queue counter to zero
            work_progress.StoreQueueLength(0, queue_index + 2);
        }

        // Barrier to protect work decomposition
        __syncthreads();

        SweepPass<KernelPolicy, Problem, Functor>::Invoke(
                //iteration,
                label,
                queue_index,
                //num_gpus,
                d_in,
                d_value_in,
                d_out,
                d_data_slice,
                d_visited_mask,
                smem_storage,
                work_progress,
                smem_storage.state.work_decomposition,
                max_out_frontier);
		//t_bitmask);

        //if (KernelPolicy::INSTRUMENT && (threadIdx.x == 0)) {
        //    kernel_stats.MarkStop();
        //    kernel_stats.Flush();
        //}
    }

    static __device__ __forceinline__ void  Kernel2(
            //VertexId &iteration,
            LabelT &label,
            bool &queue_reset,
            VertexId &queue_index,
            //int &num_gpus,
            SizeT &num_elements,
            //volatile int *&d_done,
            VertexId *&d_in_queue,
            VertexId *&d_out_queue,
            DataSlice *&d_data_slice,
            util::CtaWorkProgress<SizeT> &work_progress,
            SizeT &max_in_frontier,
            SizeT &max_out_frontier,
            util::KernelRuntimeStats &kernel_stats)
    {
      /*// Shared storage for the kernel
        __shared__ typename KernelPolicy::SmemStorage smem_storage;

        if (KernelPolicy::INSTRUMENT && (threadIdx.x == 0)) {
            kernel_stats.MarkStart();
        }

        // workprogress reset
        if (queue_reset)
        {
            if (threadIdx.x < gunrock::util::CtaWorkProgress::COUNTERS) {
                //Reset all counters
                work_progress.template Reset<SizeT>();
            }
        }


        // Determine work decomposition
        if (threadIdx.x == 0) {
            // Obtain problem size
            if (queue_reset)
            {
                work_progress.template StoreQueueLength<SizeT>(num_elements, queue_index);
            }
            else
            {
                num_elements = work_progress.template LoadQueueLength<SizeT>(queue_index);

                // Check if we previously overflowed
                if (num_elements >= max_in_frontier) {
                    num_elements = 0;
                }

                // Signal to host that we're done
                if ((num_elements == 0) ||
                        (KernelPolicy::SATURATION_QUIT && (num_elements <= gridDim.x * KernelPolicy::SATURATION_QUIT)))
                {
                    if (d_done) d_done[0] = num_elements;
                }
            }

            // Initialize work decomposition in smem
            smem_storage.state.work_decomposition.template Init<KernelPolicy::LOG_SCHEDULE_GRANULARITY>(
                    num_elements, gridDim.x);

            // Reset our next outgoing queue counter to zero
            work_progress.template StoreQueueLength<SizeT>(0, queue_index + 2);

        }

        // Barrier to protect work decomposition
        __syncthreads();*/

        SizeT my_idx = threadIdx.x + blockIdx.x * blockDim.x;
        if (my_idx >= num_elements)
            return;
        //if (my_idx == 0)
        //    printf("num elements:%d\n", num_elements);

        SizeT output_pos = my_idx;
        Functor::ApplyFilter(
            util::InvalidValue<VertexId>(),
            d_in_queue[my_idx],
            d_data_slice, /*iteration*/
            util::InvalidValue<SizeT>(),
            label,
            my_idx, output_pos);
        d_out_queue[output_pos] = d_in_queue[my_idx];

        /*if (KernelPolicy::INSTRUMENT && (threadIdx.x == 0)) {
            kernel_stats.MarkStop();
            kernel_stats.Flush();
        }*/
    }


    static __device__ __forceinline__ void MarkVisit(
                VertexId *&vertex_in,
                SizeT *&visit_lookup,
                SizeT &input_queue_length,
                SizeT &node_num)
    {
        SizeT my_id = threadIdx.x + blockIdx.x * blockDim.x;
        if (my_id >= input_queue_length)
            return;
        VertexId my_vert = vertex_in[my_id];
        // Wei's suggestion of adding the third condition
        if (my_vert < 0 || my_vert >= node_num || visit_lookup[my_vert] > 0) return;
        visit_lookup[my_vert] = my_id;
    }

    static __device__ __forceinline__ void MarkValid(
                VertexId *&vertex_in,
                SizeT *&visit_lookup,
                VertexId *&valid_in,
                SizeT &input_queue_length,
                SizeT &node_num)
    {
        int my_id = threadIdx.x + blockIdx.x * blockDim.x;
        if (my_id >= input_queue_length) return;
        VertexId my_vert = vertex_in[my_id];
        if (my_vert >= node_num) { valid_in[my_id] = 0; return; }
        valid_in[my_id] = (my_id == visit_lookup[my_vert]);
    }

    static __device__ __forceinline__ void Compact(
                VertexId *&vertex_in,
                VertexId *&vertex_out,
                VertexId *&valid_out,
                LabelT   label,
                DataSlice *&data_slice,
                SizeT &input_queue_length,
                SizeT &node_num)
    {
        int my_id = threadIdx.x + blockIdx.x * blockDim.x;
        if (my_id >= input_queue_length) return;
        VertexId my_vert = vertex_in[my_id];
        if (my_vert >= node_num) return;
        VertexId my_valid = valid_out[my_id];
        if (my_valid == valid_out[my_id+1]-1)
            vertex_out[my_valid] = my_vert;
        if (Functor::CondFilter(
            util::InvalidValue<VertexId>(),
            vertex_in[my_id],
            data_slice,
            util::InvalidValue<SizeT>(),
            label,
            util::InvalidValue<SizeT>(),
            util::InvalidValue<SizeT>()))
            Functor::ApplyFilter(
            util::InvalidValue<VertexId>(),
            vertex_in[my_id],
            data_slice,
            util::InvalidValue<SizeT>(),
            label,
            util::InvalidValue<SizeT>(),
            util::InvalidValue<SizeT>());
    }

};

/**
 * @brief Filter kernel entry point.
 *
 * @tparam KernelPolicy Kernel policy type for filter.
 * @tparam Problem Problem data type for filter.
 * @tparam Functor Functor type for the specific problem type.
 *
 * @param[in] iteration     Current graph traversal iteration
 * @param[in] queue_reset   If reset queue counter
 * @param[in] queue_index   Current frontier queue counter index
 * @param[in] num_gpus      Number of GPUs
 * @param[in] num_elements  Number of elements
 * @param[in] d_done        pointer of volatile int to the flag to set when we detect incoming frontier is empty
 * @param[in] d_in_queue    pointer of VertexId to the incoming frontier queue
 * @param[in] d_in_predecessor_queue pointer of VertexId to the incoming predecessor queue (only used when both mark_predecessor and enable_idempotence are set)
 * @param[in] d_out_queue   pointer of VertexId to the outgoing frontier queue
 * @param[in] problem       Device pointer to the problem object
 * @param[in] d_visited_mask Device pointer to the visited mask queue
 * @param[in] work_progress queueing counters to record work progress
 * @param[in] max_in_queue  Maximum number of elements we can place into the incoming frontier
 * @param[in] max_out_queue Maximum number of elements we can place into the outgoing frontier
 * @param[in] kernel_stats  Per-CTA clock timing statistics (used when KernelPolicy::INSTRUMENT is set)
 * @param[in] filtering_flag Boolean value indicates whether to filter out elements in the frontier (if not don't use scan+scatter, just apply computation to each element)
 */
template <typename KernelPolicy, typename Problem, typename Functor>
__launch_bounds__ (KernelPolicy::THREADS, KernelPolicy::CTA_OCCUPANCY)
__global__
void Kernel(
    //typename KernelPolicy::VertexId         iteration,
    typename Functor::LabelT                label,
    bool                                    queue_reset,
    typename KernelPolicy::VertexId         queue_index,
    typename KernelPolicy::SizeT            num_elements,
    typename KernelPolicy::VertexId         *d_in_queue,
    typename KernelPolicy::Value            *d_in_value_queue,
    typename KernelPolicy::VertexId         *d_out_queue,
    typename Problem::DataSlice             *d_data_slice,
    unsigned char                           *d_visited_mask,
    util::CtaWorkProgress<typename KernelPolicy::SizeT> work_progress,
    typename KernelPolicy::SizeT            max_in_queue,
    typename KernelPolicy::SizeT            max_out_queue,
    util::KernelRuntimeStats                kernel_stats,
    bool                                    filtering_flag = true)
{
    if (filtering_flag) {
        Dispatch<KernelPolicy, Problem, Functor>::Kernel(
                //iteration,
                label,
                queue_reset,
                queue_index,
                //num_gpus,
                num_elements,
                //d_done,
                d_in_queue,
                d_in_value_queue,
                d_out_queue,
                d_data_slice,
                d_visited_mask,
                work_progress,
                max_in_queue,
                max_out_queue,
                kernel_stats);
    } else {
        Dispatch<KernelPolicy, Problem, Functor>::Kernel2(
                //iteration,
                label,
                queue_reset,
                queue_index,
                //num_gpus,
                num_elements,
                //d_done,
                d_in_queue,
                d_out_queue,
                d_data_slice,
                work_progress,
                max_in_queue,
                max_out_queue,
                kernel_stats);
    }
}

template<typename KernelPolicy, typename Problem, typename Functor>
__launch_bounds__ (KernelPolicy::THREADS, KernelPolicy::CTA_OCCUPANCY)
    __global__
void MarkVisit(
        typename KernelPolicy::VertexId *vertex_in,
        typename KernelPolicy::SizeT *visit_lookup,
        typename KernelPolicy::SizeT input_queue_length,
        typename KernelPolicy::SizeT node_num)
{
    Dispatch<KernelPolicy, Problem, Functor>::MarkVisit(
    vertex_in,
    visit_lookup,
    input_queue_length,
    node_num);
}

template<typename KernelPolicy, typename Problem, typename Functor>
__launch_bounds__ (KernelPolicy::THREADS, KernelPolicy::CTA_OCCUPANCY)
    __global__
void MarkValid(
        typename KernelPolicy::VertexId *vertex_in, 
        typename KernelPolicy::SizeT *visit_lookup,
        typename KernelPolicy::VertexId *valid_in,
        typename KernelPolicy::SizeT input_queue_length,
        typename KernelPolicy::SizeT node_num)
{
    Dispatch<KernelPolicy, Problem, Functor>::MarkValid(
    vertex_in,
    visit_lookup,
    valid_in,
    input_queue_length,
    node_num);
}

template<typename KernelPolicy, typename Problem, typename Functor>
__launch_bounds__ (KernelPolicy::THREADS, KernelPolicy::CTA_OCCUPANCY)
    __global__
void Compact(
        typename KernelPolicy::VertexId *vertex_in,
        typename KernelPolicy::VertexId *vertex_out, 
        typename KernelPolicy::VertexId *valid_out,
        typename Functor::LabelT                label,
        typename Problem::DataSlice *data_slice,
        typename KernelPolicy::SizeT input_queue_length,
        typename KernelPolicy::SizeT node_num)
{
    Dispatch<KernelPolicy, Problem, Functor>::Compact(
    vertex_in,
    vertex_out,
    valid_out,
    label,
    data_slice,
    input_queue_length,
    node_num);
}

template <typename KernelPolicy, typename Problem, typename Functor>
void LaunchKernel(
    unsigned int                            grid_size,
    unsigned int                            block_size,
    size_t                                  shared_size,
    cudaStream_t                            stream,
    //long long                               iteration,
    typename Functor::LabelT                label,
    bool                                    queue_reset,
    unsigned int                            queue_index,
    typename KernelPolicy::SizeT            num_elements,
    typename KernelPolicy::VertexId         *d_in_queue,
    typename KernelPolicy::Value            *d_in_value_queue,
    typename KernelPolicy::VertexId         *d_out_queue,
    typename Problem::DataSlice             *d_data_slice,
    unsigned char                           *d_visited_mask,
    util::CtaWorkProgress<typename KernelPolicy::SizeT> work_progress,
    typename KernelPolicy::SizeT            max_in_queue,
    typename KernelPolicy::SizeT            max_out_queue,
    util::KernelRuntimeStats                kernel_stats,
    bool                                    filtering_flag = true)
{
    if (queue_reset)
        work_progress.Reset_(0, stream);
    switch (KernelPolicy::FILTER_MODE)
    {
        case CULL:
            {
                Kernel<KernelPolicy, Problem, Functor>
                    <<<grid_size, block_size, shared_size, stream>>>(
                            label,
                            queue_reset,
                            queue_index,
                            num_elements,
                            d_in_queue,
                            d_in_value_queue,
                            d_out_queue,
                            d_data_slice,
                            d_visited_mask,
                            work_progress,
                            max_in_queue,
                            max_out_queue,
                            kernel_stats,
                            filtering_flag);
                break;
            }
        case SIMPLIFIED:
            {

                //d_data_slice->valid_in.GetPointer(util::DEVICE)
                //d_data_slice->valid_out.GetPointer(util::DEVICE)
                // launch settings
                int num_block = (num_elements + KernelPolicy::THREADS - 1) / KernelPolicy::THREADS;
                // MarkVisit
                MarkVisit<KernelPolicy, Problem, Functor>
                <<<num_block, KernelPolicy::THREADS>>>
                (d_in_queue,
                d_data_slice->visit_lookup[0].GetPointer(util::DEVICE),
                num_elements, max_in_queue);
                // MarkValid
                MarkValid<KernelPolicy, Problem, Functor>
                <<<num_block, KernelPolicy::THREADS>>>
                (d_in_queue,
                d_data_slice->visit_lookup[0].GetPointer(util::DEVICE),
                d_data_slice->valid_in[0].GetPointer(util::DEVICE),
                num_elements, max_in_queue);
                // ExcScan of num_elements+1
                void *d_temp_storage = NULL;
                size_t temp_storage_bytes = 0;
                cub::DeviceScan::ExclusiveSum(d_temp_storage, temp_storage_bytes, d_data_slice->valid_in[0].GetPointer(util::DEVICE), d_data_slice->valid_out[0].GetPointer(util::DEVICE), num_elements+1);
                cudaMalloc(&d_temp_storage, temp_storage_bytes);
                cub::DeviceScan::ExclusiveSum(d_temp_storage, temp_storage_bytes, d_data_slice->valid_in[0].GetPointer(util::DEVICE), d_data_slice->valid_out[0].GetPointer(util::DEVICE), num_elements+1);
                // Compact
                Compact<KernelPolicy, Problem, Functor>
                <<<num_block, KernelPolicy::THREADS>>>
                (d_in_queue, d_out_queue,
                d_data_slice->valid_out[0].GetPointer(util::DEVICE),
                label,
                d_data_slice,
                num_elements, max_in_queue);
                break;
            }
        default:
            break;
    }
}


} // namespace filter
} // namespace oprtr
} // namespace gunrock

// Leave this at the end of the file
// Local Variables:
// mode:c++
// c-file-style: "NVIDIA"
// End:
