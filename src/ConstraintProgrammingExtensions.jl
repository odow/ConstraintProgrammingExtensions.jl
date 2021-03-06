module ConstraintProgrammingExtensions
  using MathOptInterface

  """
      AllDifferent(dimension::Int)
  The set corresponding to an all-different constraint.
  All expressions of a vector-valued function are enforced to take distinct
  values in the solution: for all pairs of expressions, their values must
  differ.
  This constraint is sometimes called `distinct`.
  ## Example
      [x, y, z] in AllDifferent(3)
      # enforces `x != y` AND `x != z` AND `y != z`.
  """
  struct AllDifferent <: AbstractVectorSet
      dimension::Int
  end

  """
      Domain{T <: Number}(values::Set{T})
  The set corresponding to an enumeration of constant values.
  The value of a scalar function is enforced to take a value from this set of
  values.
  This constraint is sometimes called `in`.
  ## Example
      x in Domain(Set(1, 2, 3))
      # enforces `x == 1` OR `x == 2` OR `x == 3`.
  """
  struct Domain{T <: Number} <: AbstractScalarSet
      values::Set{T}
  end

  function Base.copy(set::Domain{T}) where T
      return Domain(copy(set.values))
  end

  """
      Membership(dimension)
  The first element of a function of dimension `dimension` must equal at least
  one of the following `dimension - 1` elements of the function.
  This constraint is sometimes called `in_set`.
  ## Example
      [x, y, z] in Membership(dimension)
      # enforces `x == y` OR `x == z`.
  """
  struct Membership <: AbstractScalarSet
      values::Set{AbstractScalarFunction}
  end

  function Base.copy(set::Membership)
      return Domain(copy(set.values))
  end

  """
      DifferentFrom(dimension)
  The first element of a function of dimension `dimension` cannot equal any
  of the following `dimension - 1` elements of the function.
  ## Example
      [x, y, z] in DifferentFrom(dimension)
      # enforces `x != y` AND `x != z`.
  """
  struct DifferentFrom <: AbstractScalarSet
      dimension::Int
  end

  """
      Count{T <: Real}(value::T, dimension::Int)
  ``\\{(y, x) \\in \\mathbb{N} \\times \\mathbb{R}^n : y = |\\{i | x_i = value\\}|\\}``
  """
  struct Count{T <: Real} <: AbstractVectorSet
      value::T
      dimension::Int
  end

  dimension(set::Count{T}) where T = set.dimension + 1

  function Base.copy(set::Count)
      return Count(copy(set.value), value)
  end

  """
      CountDistinct(dimension::Int)
  The first variable in the set is forced to be the number of distinct values in the rest of the expressions.
  Also called `nvalues`. This is a relaxed version of `AllDifferent`; it encodes an `AllDifferent` constraint
  when the first variable is the number of variables in the set.
  """
  struct CountDistinct <: AbstractVectorSet
      dimension::Int
  end

  dimension(set::CountDistinct) where T = set.dimension + 1

  """
      Strictly{S <: Union{LessThan, GreaterThan}}
  Converts an inequality set to a set with the same inequality made strict. For instance, while LessThan(1)
  corresponds to the inequality `<= 1`, Strictly(LessThan(1)) corresponds to the inequality `< 1`, i.e.
  the value 1 is no more allowed.
  """
  struct Strictly{S <: Union{LessThan, GreaterThan}} <: AbstractScalarSet
      set::S
  end

  function Base.copy(set::Strictly{S}) where S
      return Count(copy(set.set))
  end

  """
      Element{T <: Real}(values::Vector{T})
  ``\\{(x, i) \\in \\mathbb{R}^d \\times \\mathbb{N}^d | x_j = values[i_j]\\}``
  Less formally, the j-th element constrained in this set will take the value of `values` at the index given by
  the (j + dimension)-th element.
  ## Examples
      [x, 3] in Element([4, 5, 6])
      # Enforces that x = 6, because 6 is the 3rd element from the array.
      [x, 3, y, j] in Element([4, 5, 6])
      # Enforces that x = 6, because 6 is the 3rd element from the array.
      # Enforces that y = array[j], depending on the value of j (an integer between 1 and 3).
  """
  struct Element{T <: Real} <: AbstractVectorSet
      values::Vector{T}
      dimension::Int
  end

  dimension(set::Element{T}) where T = 2 * set.dimension

  function Base.copy(set::Element{T}) where T
      return Element(copy(set.values), set.dimension)
  end

  """
      Sort(dimension::Int)
  Ensures that the first `dimension` elements is a sorted copy of the next `dimension` elements.
  ## Example
      [a, b, c, d] in Sort(2)
      # Enforces that:
      # - the first part is sorted: a <= b
      # - the first part corresponds to the second one:
      #     - either a = c and b = d
      #     - or a = d and b = c
  """
  struct Sort <: AbstractVectorSet
      dimension::Int
  end

  dimension(set::Sort) where T = 2 * set.dimension

  """
      SortPermutation(dimension::Int)
  Ensures that the first `dimension` elements is a sorted copy of the next `dimension` elements.
  The last `dimension` elemenst give a permutation to get from the original array to its sorted version.
  ## Example
      [a, b, c, d, i, j] in SortPermutation(2)
      # Enforces that:
      # - the first part is sorted: a <= b
      # - the first part corresponds to the second one:
      #     - either a = c and b = d: in this case, i = 1 and j = 2
      #     - or a = d and b = c: in this case, i = 2 and j = 1
  """
  struct SortPermutation <: AbstractVectorSet
      dimension::Int
  end

  dimension(set::SortPermutation) where T = 3 * set.dimension

  """
      BinPacking(n_bins::Int, n_items::Int)
  Implements an uncapacitated version of the bin packing. The first `n_bins` variables give the load in each bin,
  the next `n_items` give the number of the bin to which the item is assigned to, and the last `n_items` ones
  give the size of each item. The load of a bin is defined as the sum of the sizes of the items put in that bin.
  Also called `pack`.
  ## Example
      [a, b, c, d, e] in BinPacking(1, 2)
      # As there is only one bin, the only solution is to put all the items in that bin.
      # Enforces that:
      # - the bin load is the sum of the objects in that bin: a = d + e
      # - the bin number of the two items is 1: b = c = 1
  """
  struct BinPacking <: AbstractVectorSet
      n_bins::Int
      n_items::Int
  end

  dimension(set::BinPacking) where T = set.n_bins + 2 * set.n_items

  """
      CapacitatedBinPacking(n_bins::Int, n_items::Int)
  Implements an uncapacitated version of the bin packing. The first `n_bins` variables give the load in each bin,
  the next `n_bins` are the capacity of each bin, the followin `n_items` give the number of the bin to which the item
  is assigned to, and the last `n_items` ones give the size of each item. The load of a bin is defined as the sum
  of the sizes of the items put in that bin.
  This constraint is equivalent to `BinPacking` with inequality constraints on the loads of the bins. However, there
  are more efficient propagators for the combined constraint (bin packing with maximum load).
  Also called `bin_packing_capa`.
  ## Example
      [a, 2, b, c, d, e] in CapacitatedBinPacking(1, 2)
      # As there is only one bin, the only solution is to put all the items in that bin if its capacity is large enough.
      # Enforces that:
      # - the bin load is the sum of the objects in that bin: a = d + e
      # - the bin load is at most its capacity: a <= 2
      # - the bin number of the two items is 1: b = c = 1
  """
  struct CapacitatedBinPacking <: AbstractVectorSet
      n_bins::Int
      n_items::Int
  end

  dimension(set::CapacitatedBinPacking) where T = 2 * set.n_bins + 2 * set.n_items

  """
      ReificationSet{S <: AbstractScalarSet}(set::S)
  ``\\{(y, x) \\in \\{0, 1\\} \\times \\mathbb{R}^n | y = 1 \\iff x \\in set, y = 0 otherwise\\}``.
  `S` has to be a sub-type of `AbstractScalarSet`.
  This set serves to find out whether a given constraint is satisfied. The only possible values are
  0 and 1.
  """
  struct ReificationSet{S <: AbstractScalarSet} <: AbstractVectorSet
      set::S
      dimension::Int
  end

  dimension(set::ReificationSet{T}) where T = set.dimension + 1

  function Base.copy(set::ReificationSet{S}) where S
      return ReificationSet(copy(set.set), set.dimension)
  end

  # isbits types, nothing to copy
  function Base.copy(
      set::Union{AllDifferent, DifferentFrom, CountDistinct, Element,
          BinPacking, CapacitatedBinPacking, DifferentFrom}
  )
      return set
  end
end
